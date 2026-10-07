import { money } from '../../../common/utils/money';
import { Prisma } from '../../../generated/prisma/client';

const byOrder = { orderBy: { sortOrder: 'asc' } } as const;

export const adminProductInclude = {
  variants: byOrder,
  options: { ...byOrder, include: { values: byOrder } },
} satisfies Prisma.ProductInclude;

export const adminStoreInclude = {
  categories: { select: { categoryId: true } },
  schedules: { orderBy: [{ dayOfWeek: 'asc' }, { opensAt: 'asc' }] },
  menuSections: byOrder,
  products: {
    where: { deletedAt: null },
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    include: adminProductInclude,
  },
} satisfies Prisma.StoreInclude;

type AdminProduct = Prisma.ProductGetPayload<{ include: typeof adminProductInclude }>;
type AdminStore = Prisma.StoreGetPayload<{ include: typeof adminStoreInclude }>;

/** Vista de edición: todo lo que el admin puede cambiar, con los ids para editar en bloque. */
export function toAdminProduct(p: AdminProduct, currency: string) {
  return {
    id: p.id,
    storeId: p.storeId,
    menuSectionId: p.menuSectionId,
    name: p.name,
    description: p.description,
    imageUrl: p.imageUrl,
    basePrice: money(p.basePrice, currency),
    isAvailable: p.isAvailable,
    stock: p.stock,
    isFeatured: p.isFeatured,
    isLocal: p.isLocal,
    sortOrder: p.sortOrder,
    variants: p.variants.map((v) => ({
      id: v.id,
      name: v.name,
      price: money(v.price, currency),
      isAvailable: v.isAvailable,
      sortOrder: v.sortOrder,
    })),
    options: p.options.map((o) => ({
      id: o.id,
      name: o.name,
      minSelect: o.minSelect,
      maxSelect: o.maxSelect,
      sortOrder: o.sortOrder,
      values: o.values.map((v) => ({
        id: v.id,
        name: v.name,
        priceDelta: money(v.priceDelta, currency),
        isAvailable: v.isAvailable,
        sortOrder: v.sortOrder,
      })),
    })),
  };
}

export function toAdminStore(s: AdminStore, currency: string) {
  return {
    id: s.id,
    cityId: s.cityId,
    ownerId: s.ownerId,
    name: s.name,
    slug: s.slug,
    description: s.description,
    logoUrl: s.logoUrl,
    coverUrl: s.coverUrl,
    phone: s.phone,
    addressLine: s.addressLine,
    latitude: Number(s.latitude),
    longitude: Number(s.longitude),
    deliveryRadiusKm: s.deliveryRadiusKm === null ? null : Number(s.deliveryRadiusKm),
    minOrderAmount: money(s.minOrderAmount, currency),
    avgPrepMinutes: s.avgPrepMinutes,
    tags: s.tags,
    promoLabel: s.promoLabel,
    ownerDisplayName: s.ownerDisplayName,
    attendingSince: s.attendingSince,
    isActive: s.isActive,
    isAcceptingOrders: s.isAcceptingOrders,
    categoryIds: s.categories.map((c) => c.categoryId),
    schedules: s.schedules.map(({ dayOfWeek, opensAt, closesAt }) => ({ dayOfWeek, opensAt, closesAt })),
    sections: s.menuSections.map(({ id, name, sortOrder }) => ({ id, name, sortOrder })),
    products: s.products.map((p) => toAdminProduct(p, currency)),
  };
}
