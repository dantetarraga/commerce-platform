import { GeoPoint } from '../../common/utils/geo';
import { Money, money } from '../../common/utils/money';
import { isOpenAt, localTime, OpeningHours } from '../../common/utils/schedule';
import { Prisma } from '../../generated/prisma/client';
import type { CityContext } from '../cities/cities.service';
import { DeliveryEstimate, estimateDelivery } from '../delivery/delivery';

// Proyecciones de BD → JSON de la API. Son funciones puras: los services
// cargan los datos y estas los convierten al contrato de la app.

export const storeSummaryInclude = {
  categories: { select: { categoryId: true } },
  schedules: { orderBy: [{ dayOfWeek: 'asc' }, { opensAt: 'asc' }] },
} satisfies Prisma.StoreInclude;

export type StoreForSummary = Prisma.StoreGetPayload<{ include: typeof storeSummaryInclude }>;

/** `StoreSummaryDto` de la app (item de `GET /stores`). */
export interface StoreSummary {
  id: string;
  name: string;
  logoUrl: string | null;
  coverUrl: string | null;
  categoryIds: string[];
  ratingAvg: number;
  ratingCount: number;
  distanceKm: number;
  etaMinutes: number;
  estimatedDeliveryFee: Money;
  minOrderAmount: Money;
  isOpenNow: boolean;
  deliversToYou: boolean;
  tags: string[];
  promoLabel: string | null;
}

export function storeDelivery(store: StoreForSummary, city: CityContext, point: GeoPoint): DeliveryEstimate {
  return estimateDelivery(
    {
      location: { lat: Number(store.latitude), lng: Number(store.longitude) },
      deliveryRadiusKm: store.deliveryRadiusKm === null ? null : Number(store.deliveryRadiusKm),
      avgPrepMinutes: store.avgPrepMinutes,
    },
    point,
    city.tariff,
  );
}

/** Abierto = activo, aceptando pedidos y dentro de su horario (hora local de la ciudad). */
export function isStoreOpen(store: StoreForSummary, city: CityContext, now: Date): boolean {
  return store.isAcceptingOrders && isOpenAt(store.schedules, localTime(now, city.timezone));
}

export function toStoreSummary(store: StoreForSummary, city: CityContext, point: GeoPoint, now: Date): StoreSummary {
  const delivery = storeDelivery(store, city, point);
  return {
    id: store.id,
    name: store.name,
    logoUrl: store.logoUrl,
    coverUrl: store.coverUrl,
    categoryIds: store.categories.map((c) => c.categoryId),
    ratingAvg: Number(store.ratingAvg),
    ratingCount: store.ratingCount,
    distanceKm: delivery.distanceKm,
    etaMinutes: delivery.etaMinutes,
    estimatedDeliveryFee: money(delivery.fee, city.currency),
    minOrderAmount: money(store.minOrderAmount, city.currency),
    isOpenNow: isStoreOpen(store, city, now),
    deliversToYou: delivery.deliversToYou,
    tags: store.tags,
    promoLabel: store.promoLabel,
  };
}

export function toStoreDetail(store: StoreForSummary, city: CityContext, point: GeoPoint, now: Date) {
  return {
    ...toStoreSummary(store, city, point, now),
    description: store.description,
    addressLine: store.addressLine,
    phone: store.phone,
    schedules: store.schedules.map(({ dayOfWeek, opensAt, closesAt }): OpeningHours => ({
      dayOfWeek,
      opensAt,
      closesAt,
    })),
    ownerName: store.ownerDisplayName,
    attendingSince: store.attendingSince,
  };
}

// ───────────────────────── Productos en listas ─────────────────────────

export const productCardInclude = {
  variants: { select: { price: true, isAvailable: true } },
  _count: { select: { options: true } },
} satisfies Prisma.ProductInclude;

export type ProductForCard = Prisma.ProductGetPayload<{ include: typeof productCardInclude }>;

/** `MenuItemDto` de la app. */
export interface MenuItem {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  price: Money;
  isAvailable: boolean;
  hasChoices: boolean;
  isFeatured: boolean;
}

/** Disponible = marcado disponible, con stock (si se controla) y con alguna variante disponible. */
export function isProductAvailable(product: {
  isAvailable: boolean;
  stock: number | null;
  variants: { isAvailable: boolean }[];
}): boolean {
  return (
    product.isAvailable &&
    (product.stock === null || product.stock > 0) &&
    (product.variants.length === 0 || product.variants.some((v) => v.isAvailable))
  );
}

/** Precio "desde": la variante disponible más barata, o el precio base si no hay variantes. */
export function fromPrice(product: ProductForCard): number {
  const prices = product.variants.filter((v) => v.isAvailable).map((v) => v.price);
  return prices.length ? Math.min(...prices) : product.basePrice;
}

export function toMenuItem(product: ProductForCard, currency: string): MenuItem {
  return {
    id: product.id,
    name: product.name,
    description: product.description,
    imageUrl: product.imageUrl,
    price: money(fromPrice(product), currency),
    isAvailable: isProductAvailable(product),
    hasChoices: product.variants.length > 0 || product._count.options > 0,
    isFeatured: product.isFeatured,
  };
}
