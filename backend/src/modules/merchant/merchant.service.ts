import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/exceptions/app.exception';
import { DEFAULT_TIMEZONE, zonedTime } from '../../common/time';
import { money } from '../../common/utils/money';
import { isOpenAt } from '../../common/utils/schedule';
import { PrismaService } from '../../database/prisma.service';
import type { Prisma } from '../../generated/prisma/client';
import { fromPrice, productCardInclude } from '../stores/store-presenter';
import { visibleStore } from '../stores/stores.service';
import { summarizeMerchantDay } from './merchant-summary';

/** `ownerId` limita a los negocios de ese dueño; sin él (admin), todos. */
const ownedStores = (ownerId?: string): Prisma.StoreWhereInput => ({
  ...visibleStore,
  ...(ownerId && { ownerId }),
});

/**
 * Lo que el negocio administra desde Chaski Socios además de sus pedidos:
 * sus locales, la disponibilidad de productos y el resumen del día.
 */
@Injectable()
export class MerchantService {
  constructor(private readonly prisma: PrismaService) {}

  /** Sus negocios. `isOpenNow` mira solo el horario; la pausa manual va en `isAcceptingOrders`. */
  async stores(ownerId?: string, now = new Date()) {
    const stores = await this.prisma.store.findMany({
      where: ownedStores(ownerId),
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        logoUrl: true,
        isAcceptingOrders: true,
        schedules: true,
        city: { select: { timezone: true } },
      },
    });
    return stores.map((store) => ({
      id: store.id,
      name: store.name,
      logoUrl: store.logoUrl,
      isAcceptingOrders: store.isAcceptingOrders,
      isOpenNow: isOpenAt(store.schedules, zonedTime.localTime(now, store.city.timezone)),
    }));
  }

  /** Productos del negocio (sin los borrados), en el orden del menú. */
  async products(storeId: string, ownerId?: string) {
    const store = await this.prisma.store.findFirst({
      where: { id: storeId, ...ownedStores(ownerId) },
      select: { city: { select: { currency: true } } },
    });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');

    const products = await this.prisma.product.findMany({
      where: { storeId, deletedAt: null },
      orderBy: [{ menuSection: { sortOrder: 'asc' } }, { sortOrder: 'asc' }, { name: 'asc' }],
      include: { ...productCardInclude, menuSection: { select: { name: true } } },
    });
    return products.map((product) => ({
      id: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      price: money(fromPrice(product), store.city.currency),
      section: product.menuSection?.name ?? null,
      isAvailable: product.isAvailable,
    }));
  }

  /** Marca un producto disponible o agotado. Uno de otro negocio responde 404. */
  async setProductAvailable(productId: string, isAvailable: boolean, ownerId?: string) {
    const { count } = await this.prisma.product.updateMany({
      where: { id: productId, deletedAt: null, store: ownedStores(ownerId) },
      data: { isAvailable },
    });
    if (count === 0) throw AppException.notFound('No encontramos ese producto.');
    return { id: productId, isAvailable };
  }

  /** Pedidos creados ese día (hora local) en sus negocios. */
  async summary(date: string | undefined, ownerId?: string, now = new Date()) {
    const day = date ?? zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const { start, end } = zonedTime.dayRange(day, DEFAULT_TIMEZONE);
    const orders = await this.prisma.order.findMany({
      where: { createdAt: { gte: start, lt: end }, ...(ownerId && { store: { ownerId } }) },
      select: { status: true, subtotal: true },
    });
    const { sales, ...counts } = summarizeMerchantDay(orders);
    return { date: day, ...counts, sales: money(sales) };
  }
}
