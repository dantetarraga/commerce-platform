import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/exceptions/app.exception';
import { GeoPoint } from '../../common/utils/geo';
import { PrismaService } from '../../database/prisma.service';
import type { Prisma } from '../../generated/prisma/client';
import { storeProductIds } from '../search/search.queries';
import { CitiesService, CityContext } from '../cities/cities.service';
import { deliverySlots } from './delivery-slots';
import { matchesFilters, openFirst } from './store-filters';
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
    if (!city) return { items: [], page: query.page, limit: query.limit, total: 0, openCount: 0 };

    const stores = await this.prisma.store.findMany({
      where: {
        ...visibleStore,
        cityId: city.id,
        ...(query.categoryId && { categories: { some: { categoryId: query.categoryId } } }),
      },
      include: storeSummaryInclude,
    });

    const at = point ?? city.center;
    const reachable = stores
      .map((store) => ({ store, summary: toStoreSummary(store, city, at, now) }))
      .filter(({ summary }) => query.includeOutOfCoverage || summary.deliversToYou)
      .sort(comparator(query.sort));
    const filtered = reachable.filter(({ summary }) => matchesFilters(summary, query.filters));
    const rows = query.openFirst ? openFirst(filtered, ({ summary }) => summary.isOpenNow) : filtered;

    const start = (query.page - 1) * query.limit;
    return {
      items: rows.slice(start, start + query.limit).map(({ summary }) => summary),
      page: query.page,
      limit: query.limit,
      total: rows.length,
      /** Abiertos ahora entre los que llegan a la ubicación, sin contar los filtros. */
      openCount: reachable.filter(({ summary }) => summary.isOpenNow).length,
    };
  }

  /** Negocios abiertos ahora que llegan a la ubicación, por id de categoría. */
  async openCountByCategory(point?: GeoPoint, now = new Date()): Promise<Map<string, number>> {
    const city = await this.cities.resolve(point);
    const counts = new Map<string, number>();
    if (!city) return counts;
    const stores = await this.prisma.store.findMany({
      where: { ...visibleStore, cityId: city.id },
      include: storeSummaryInclude,
    });
    for (const store of stores) {
      const summary = toStoreSummary(store, city, point ?? city.center, now);
      if (!summary.deliversToYou || !summary.isOpenNow) continue;
      for (const id of summary.categoryIds) counts.set(id, (counts.get(id) ?? 0) + 1);
    }
    return counts;
  }

  async detail(storeId: string, point?: GeoPoint, now = new Date()) {
    const { store, city } = await this.load(storeId);
    return toStoreDetail(store, city, point ?? city.center, now);
  }

  /** Horas para programar los próximos 3 días; con el negocio en pausa, ninguna. */
  async deliverySlots(storeId: string, now = new Date()) {
    const { store, city } = await this.load(storeId);
    const days = deliverySlots(store.isAcceptingOrders ? store.schedules : [], now, city.timezone);
    return { days: days.map((day) => ({ date: day.date, slots: day.slots.map((at) => at.toISOString()) })) };
  }

  /**
   * Busca en la carta del negocio (nombre y descripción, sin tildes), en el
   * orden de la carta y sin repetir. Sin texto: toda la carta.
   */
  async searchMenu(storeId: string, query?: string) {
    const { city } = await this.load(storeId);
    const ids = query ? await storeProductIds(this.prisma, storeId, query) : null;
    const products = await this.prisma.product.findMany({
      where: { storeId, deletedAt: null, ...(ids && { id: { in: ids } }) },
      orderBy: [{ menuSection: { sortOrder: 'asc' } }, { sortOrder: 'asc' }, { name: 'asc' }],
      include: productCardInclude,
    });
    return { items: products.map((product) => toMenuItem(product, city.currency)) };
  }

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
