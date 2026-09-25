import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/exceptions/app.exception';
import { GeoPoint } from '../../common/utils/geo';
import { PrismaService } from '../../database/prisma.service';
import type { Prisma } from '../../generated/prisma/client';
import { CitiesService, CityContext } from '../cities/cities.service';
import type { StoreSort, StoresQueryDto } from './dto/stores-query.dto';
import {
  productCardInclude,
  StoreForSummary,
  StoreSummary,
  storeSummaryInclude,
  toMenuItem,
  toStoreDetail,
  toStoreSummary,
} from './store-presenter';

/** Negocio visible para clientes. */
export const visibleStore = { isActive: true, deletedAt: null } satisfies Prisma.StoreWhereInput;

const STORE_NOT_FOUND = 'Este negocio ya no está disponible.';

@Injectable()
export class StoresService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cities: CitiesService,
  ) {}

  /**
   * Negocios de la ciudad con distancia, fee, ETA y horario calculados para la
   * ubicación. Una ciudad pequeña tiene pocas decenas de negocios, así que se
   * ordena y pagina en memoria; con volumen real se prefiltra por bounding box.
   */
  async list(query: StoresQueryDto, point?: GeoPoint, now = new Date()) {
    const city = await this.cities.resolve(point);
    if (!city) return { items: [], page: query.page, limit: query.limit, total: 0 };

    const stores = await this.prisma.store.findMany({
      where: {
        ...visibleStore,
        cityId: city.id,
        ...(query.categoryId && { categories: { some: { categoryId: query.categoryId } } }),
      },
      include: storeSummaryInclude,
    });

    const at = point ?? city.center;
    const rows = stores
      .map((store) => ({ store, summary: toStoreSummary(store, city, at, now) }))
      .filter(({ summary }) => query.includeOutOfCoverage || summary.deliversToYou)
      .sort(comparator(query.sort));

    const start = (query.page - 1) * query.limit;
    return {
      items: rows.slice(start, start + query.limit).map(({ summary }) => summary),
      page: query.page,
      limit: query.limit,
      total: rows.length,
    };
  }

  async detail(storeId: string, point?: GeoPoint, now = new Date()) {
    const { store, city } = await this.load(storeId);
    return toStoreDetail(store, city, point ?? city.center, now);
  }

  /** Menú agrupado por secciones; los productos sin sección van al final en "Otros". */
  async menu(storeId: string) {
    const { city } = await this.load(storeId);
    const [sections, unsectioned] = await Promise.all([
      this.prisma.menuSection.findMany({
        where: { storeId },
        orderBy: { sortOrder: 'asc' },
        include: {
          products: { where: { deletedAt: null }, orderBy: { sortOrder: 'asc' }, include: productCardInclude },
        },
      }),
      this.prisma.product.findMany({
        where: { storeId, menuSectionId: null, deletedAt: null },
        orderBy: { sortOrder: 'asc' },
        include: productCardInclude,
      }),
    ]);

    const all = unsectioned.length
      ? [...sections, { id: `${storeId}_otros`, name: 'Otros', products: unsectioned }]
      : sections;
    return {
      sections: all
        .filter((section) => section.products.length > 0)
        .map((section) => ({
          id: section.id,
          name: section.name,
          products: section.products.map((product) => toMenuItem(product, city.currency)),
        })),
    };
  }

  /** Pausa o reanuda pedidos. `ownerId` limita al dueño; sin él (admin), cualquiera. */
  async setAcceptingOrders(storeId: string, isAcceptingOrders: boolean, ownerId?: string) {
    const { count } = await this.prisma.store.updateMany({
      where: { id: storeId, deletedAt: null, ...(ownerId && { ownerId }) },
      data: { isAcceptingOrders },
    });
    if (count === 0) throw AppException.notFound('No encontramos ese negocio.');
    return this.prisma.store.findUniqueOrThrow({
      where: { id: storeId },
      select: { id: true, name: true, isAcceptingOrders: true },
    });
  }

  /** Para otros módulos (productos, búsqueda): negocio + su ciudad, o 404. */
  async load(storeId: string): Promise<{ store: StoreForSummary; city: CityContext }> {
    const store = await this.prisma.store.findFirst({
      where: { id: storeId, ...visibleStore },
      include: storeSummaryInclude,
    });
    if (!store) throw AppException.notFound(STORE_NOT_FOUND);
    return { store, city: await this.cities.byId(store.cityId) };
  }
}

type Row = { store: StoreForSummary; summary: StoreSummary };

function comparator(sort: StoreSort): (a: Row, b: Row) => number {
  const byName = (a: Row, b: Row) => a.store.name.localeCompare(b.store.name, 'es');
  switch (sort) {
    case 'popular':
      return (a, b) => b.store.popularityScore - a.store.popularityScore || byName(a, b);
    case 'rating':
      return (a, b) =>
        b.summary.ratingAvg - a.summary.ratingAvg || b.summary.ratingCount - a.summary.ratingCount || byName(a, b);
    case 'distance':
      return (a, b) => a.summary.distanceKm - b.summary.distanceKm || byName(a, b);
  }
}
