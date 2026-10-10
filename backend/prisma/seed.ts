/**
 * Seed de desarrollo: Espinar con el mismo catálogo que usa la app en modo
 * demo (`mobile/assets/fixtures/catalog.json`, copiado en seed-data/). Se
 * conservan los IDs para que favoritos y datos locales de la app coincidan.
 *
 * Es idempotente: se puede correr varias veces (upsert por ID).
 */
import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { CouponType, PrismaClient, Role } from '../src/generated/prisma/client';
import catalog from './seed-data/catalog.json';

type Catalog = typeof catalog;
type SeedStore = Catalog['stores'][number];

const CITY = {
  id: catalog.city.id,
  name: catalog.city.name,
  region: catalog.city.region,
  slug: 'espinar',
  currency: catalog.city.currency,
  centerLat: catalog.city.centerLat,
  centerLng: catalog.city.centerLng,
  // Con esta tarifa un pedido a menos de 1 km cuesta S/ 3.50, como en la demo.
  baseDeliveryFee: 250,
  feePerKm: 100,
  routeFactor: 1.3,
  maxDeliveryKm: 5,
  // Igual que cityCoverageKm de la app (mobile/lib/core/config/city.dart).
  coverageKm: 6,
  avgSpeedKmh: 20,
};

const VALID_FROM = new Date('2026-01-01T00:00:00Z');
const VALID_UNTIL = new Date('2030-12-31T23:59:59Z');

const DEMO_CUSTOMER = { id: 'usr_demo_customer', phone: '984123456', firstName: 'Alex', lastName: 'Quispe' };
const ADMIN = { id: 'usr_admin', phone: '900000001', firstName: 'Admin', lastName: 'Apamuy' };
const COURIERS = [
  {
    id: 'usr_courier_luis',
    phone: '900000101',
    firstName: 'Luis',
    lastName: 'Quispe',
    vehicleLabel: 'Moto roja',
    activeSince: 2023,
  },
  {
    id: 'usr_courier_yeni',
    phone: '900000102',
    firstName: 'Yeni',
    lastName: 'Mamani',
    vehicleLabel: 'Moto azul',
    activeSince: 2022,
  },
];

const COUPONS = [
  { code: 'BIENVENIDA', label: 'S/ 5 de bienvenida', type: CouponType.FIXED_AMOUNT, value: 500, minOrderAmount: 1500 },
  { code: 'ESPINAR', label: 'S/ 3 por pedir local', type: CouponType.FIXED_AMOUNT, value: 300, minOrderAmount: 0 },
  {
    code: 'BIENVENIDO10',
    label: 'S/ 10 en tu primer pedido',
    type: CouponType.FIXED_AMOUNT,
    value: 1000,
    minOrderAmount: 2000,
    firstOrderOnly: true,
  },
  {
    code: 'KANTUFREE',
    label: 'Delivery gratis en Dulce Kantu',
    type: CouponType.FREE_DELIVERY,
    value: 0,
    minOrderAmount: 3000,
    storeId: 'st_dulce_kantu',
  },
];

const POPULAR_SEARCHES = [
  'Caldo',
  'Pollo a la brasa',
  'Queso fresco',
  'Pan chuta',
  'Pizza',
  'Menú del día',
  'Paracetamol',
];

export async function seed(prisma: PrismaClient): Promise<void> {
  await prisma.city.upsert({ where: { id: CITY.id }, create: CITY, update: CITY });

  for (const [sortOrder, c] of catalog.categories.entries()) {
    const data = { name: c.name, slug: c.slug, iconUrl: c.iconUrl, sortOrder };
    await prisma.category.upsert({ where: { id: c.id }, create: { id: c.id, ...data }, update: data });
  }

  await upsertUser(prisma, DEMO_CUSTOMER, [Role.CUSTOMER]);
  await upsertUser(prisma, ADMIN, [Role.ADMIN]);
  for (const c of COURIERS) {
    const { vehicleLabel, activeSince, ...user } = c;
    await upsertUser(prisma, user, [Role.COURIER]);
    const courier = { cityId: CITY.id, vehicleType: 'MOTO', vehicleLabel, activeSince };
    await prisma.courier.upsert({ where: { userId: c.id }, create: { userId: c.id, ...courier }, update: courier });
  }

  for (const [index, store] of catalog.stores.entries()) {
    await seedStore(prisma, store, index);
  }

  for (const coupon of COUPONS) {
    const data = {
      cityId: CITY.id,
      startsAt: VALID_FROM,
      endsAt: VALID_UNTIL,
      perUserLimit: 1,
      firstOrderOnly: false,
      ...coupon,
    };
    await prisma.coupon.upsert({ where: { code: coupon.code }, create: data, update: data });
  }

  for (const [sortOrder, p] of catalog.promotions.entries()) {
    const coupon = p.couponCode ? await prisma.coupon.findUnique({ where: { code: p.couponCode } }) : null;
    const data = {
      cityId: CITY.id,
      storeId: p.storeId,
      couponId: coupon?.id ?? null,
      title: p.title,
      subtitle: p.subtitle,
      imageUrl: p.imageUrl,
      startsAt: VALID_FROM,
      endsAt: VALID_UNTIL,
      sortOrder,
    };
    await prisma.promotion.upsert({ where: { id: p.id }, create: { id: p.id, ...data }, update: data });
  }

  for (const [sortOrder, term] of POPULAR_SEARCHES.entries()) {
    await prisma.popularSearch.upsert({
      where: { cityId_term: { cityId: CITY.id, term } },
      create: { cityId: CITY.id, term, sortOrder },
      update: { sortOrder },
    });
  }
}

async function upsertUser(
  prisma: PrismaClient,
  user: { id: string; phone: string; firstName: string; lastName: string },
  roles: Role[],
) {
  await prisma.user.upsert({ where: { id: user.id }, create: user, update: user });
  for (const role of roles) {
    await prisma.userRole.upsert({
      where: { userId_role: { userId: user.id, role } },
      create: { userId: user.id, role },
      update: {},
    });
  }
}

async function seedStore(prisma: PrismaClient, s: SeedStore, index: number) {
  // Un merchant por negocio; se presenta con el nombre que usa el negocio.
  const ownerId = `usr_owner_${s.id.replace(/^st_/, '')}`;
  await upsertUser(
    prisma,
    { id: ownerId, phone: `9100000${String(index).padStart(2, '0')}`, firstName: s.ownerName ?? s.name, lastName: '' },
    [Role.MERCHANT],
  );

  const data = {
    cityId: CITY.id,
    ownerId,
    name: s.name,
    slug: s.slug,
    description: s.description,
    logoUrl: s.logoUrl,
    coverUrl: s.coverUrl,
    phone: s.phone,
    addressLine: s.addressLine,
    latitude: s.latitude,
    longitude: s.longitude,
    minOrderAmount: s.minOrderAmount,
    // La demo muestra el ETA total; aquí se guarda la preparación y el viaje se calcula.
    avgPrepMinutes: Math.max(10, s.etaMinutes - 5),
    tags: s.tags ?? [],
    promoLabel: s.promoLabel,
    ownerDisplayName: s.ownerName,
    attendingSince: s.attendingSince,
    popularityScore: s.popularity,
    ratingAvg: s.ratingAvg,
    ratingCount: s.ratingCount,
  };
  await prisma.store.upsert({ where: { id: s.id }, create: { id: s.id, ...data }, update: data });

  await prisma.storeCategory.deleteMany({ where: { storeId: s.id } });
  await prisma.storeCategory.createMany({ data: s.categoryIds.map((categoryId) => ({ storeId: s.id, categoryId })) });

  await prisma.storeSchedule.deleteMany({ where: { storeId: s.id } });
  await prisma.storeSchedule.createMany({ data: s.schedules.map((h) => ({ storeId: s.id, ...h })) });

  for (const [sortOrder, section] of s.menuSections.entries()) {
    const sectionData = { storeId: s.id, name: section.name, sortOrder };
    await prisma.menuSection.upsert({
      where: { id: section.id },
      create: { id: section.id, ...sectionData },
      update: sectionData,
    });
    for (const [productOrder, productId] of section.productIds.entries()) {
      await seedProduct(prisma, productId, section.id, productOrder);
    }
  }
}

async function seedProduct(prisma: PrismaClient, productId: string, menuSectionId: string, sortOrder: number) {
  const p = catalog.products.find((product) => product.id === productId);
  if (!p) throw new Error(`El menú referencia un producto inexistente: ${productId}`);

  const data = {
    storeId: p.storeId,
    menuSectionId,
    name: p.name,
    description: p.description,
    imageUrl: p.imageUrl,
    basePrice: p.basePrice,
    isAvailable: p.isAvailable,
    isFeatured: p.isFeatured ?? false,
    isLocal: p.isLocal ?? false,
    sortOrder,
  };
  await prisma.product.upsert({ where: { id: p.id }, create: { id: p.id, ...data }, update: data });

  for (const [order, v] of p.variants.entries()) {
    const variant = { productId: p.id, name: v.name, price: v.price, isAvailable: v.isAvailable, sortOrder: order };
    await prisma.productVariant.upsert({ where: { id: v.id }, create: { id: v.id, ...variant }, update: variant });
  }
  for (const [order, o] of p.options.entries()) {
    const option = { productId: p.id, name: o.name, minSelect: o.minSelect, maxSelect: o.maxSelect, sortOrder: order };
    await prisma.productOption.upsert({ where: { id: o.id }, create: { id: o.id, ...option }, update: option });
    for (const [valueOrder, value] of o.values.entries()) {
      const data = {
        optionId: o.id,
        name: value.name,
        priceDelta: value.priceDelta,
        isAvailable: value.isAvailable,
        sortOrder: valueOrder,
      };
      await prisma.productOptionValue.upsert({
        where: { id: value.id },
        create: { id: value.id, ...data },
        update: data,
      });
    }
  }
}

if (require.main === module) {
  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });
  seed(prisma)
    .then(() => console.log('Seed listo.'))
    .catch((error: unknown) => {
      console.error(error);
      process.exitCode = 1;
    })
    .finally(() => void prisma.$disconnect());
}
