import { Injectable } from '@nestjs/common';
import { GeoPoint } from '../../common/utils/geo';
import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';
import { CitiesService, CityContext } from '../cities/cities.service';
import {
  isProductAvailable,
  MenuItem,
  productCardInclude,
  storeSummaryInclude,
  toMenuItem,
  toStoreSummary,
} from '../stores/store-presenter';
import { visibleStore } from '../stores/stores.service';
import { popularSearchCounts, searchProductIds, searchStoreIds } from './search.queries';

const STORE_LIMIT = 20;
const PRODUCT_LIMIT = 30;
const LOCAL_PRODUCTS_LIMIT = 20;

const productHitInclude = {
  ...productCardInclude,
  store: { include: storeSummaryInclude },
} satisfies Prisma.ProductInclude;

type ProductForHit = Prisma.ProductGetPayload<{ include: typeof productHitInclude }>;

/** `ProductHitDto` de la app: un producto con el negocio que lo vende. */
export type ProductHit = MenuItem & { storeId: string; storeName: string };

/**
 * Búsqueda y descubrimiento. Solo devuelve lo que se puede pedir: negocios que
 * entregan en la ubicación y productos disponibles de esos negocios.
 */
@Injectable()
export class SearchService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cities: CitiesService,
  ) {}

  async search(query: string, point?: GeoPoint, openOnly = false, now = new Date()) {
    const city = await this.cities.resolve(point);
    if (!city) return { stores: [], products: [] };
    const at = point ?? city.center;

    const [storeIds, productIds] = await Promise.all([
      searchStoreIds(this.prisma, city.id, query, STORE_LIMIT),
      searchProductIds(this.prisma, city.id, query, PRODUCT_LIMIT),
    ]);
    const [stores, products] = await Promise.all([
      this.prisma.store.findMany({ where: { id: { in: storeIds } }, include: storeSummaryInclude }),
      this.prisma.product.findMany({ where: { id: { in: productIds } }, include: productHitInclude }),
    ]);

    return {
      stores: inOrder(storeIds, stores)
        .map((store) => toStoreSummary(store, city, at, now))
        .filter((summary) => summary.deliversToYou && (!openOnly || summary.isOpenNow)),
      products: this.toHits(inOrder(productIds, products), city, at, now),
    };
  }

  /** "Hecho en la ciudad": productos locales disponibles. */
  async localProducts(point?: GeoPoint, now = new Date()) {
    const city = await this.cities.resolve(point);
    if (!city) return { items: [] };

    const products = await this.prisma.product.findMany({
      where: { isLocal: true, isAvailable: true, deletedAt: null, store: { ...visibleStore, cityId: city.id } },
      orderBy: [{ store: { popularityScore: 'desc' } }, { sortOrder: 'asc' }],
      include: productHitInclude,
    });
    return { items: this.toHits(products, city, point ?? city.center, now).slice(0, LOCAL_PRODUCTS_LIMIT) };
  }

  async popularSearches(point?: GeoPoint) {
    const city = await this.cities.resolve(point);
    if (!city) return [];
    const rows = await popularSearchCounts(this.prisma, city.id);
    return rows.filter((row) => row.storeCount > 0);
  }

  private toHits(products: ProductForHit[], city: CityContext, at: GeoPoint, now: Date): ProductHit[] {
    return products
      .filter((p) => isProductAvailable(p) && toStoreSummary(p.store, city, at, now).deliversToYou)
      .map((p) => ({ ...toMenuItem(p, city.currency), storeId: p.storeId, storeName: p.store.name }));
  }
}

/** `findMany({ id: { in } })` no respeta el orden: se reordena según el ranking. */
function inOrder<T extends { id: string }>(ids: string[], rows: T[]): T[] {
  const byId = new Map(rows.map((row) => [row.id, row]));
  return ids.flatMap((id) => byId.get(id) ?? []);
}
