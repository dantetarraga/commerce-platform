import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/exceptions/app.exception';
import { DEFAULT_TIMEZONE, zonedTime } from '../../common/time';
import { money } from '../../common/utils/money';
import { isOpenAt } from '../../common/utils/schedule';
import { PrismaService } from '../../database/prisma.service';
import type { Prisma } from '../../generated/prisma/client';
import { fromPrice, productCardInclude } from '../stores/store-presenter';
import { visibleStore } from '../stores/stores.service';
import type { MerchantProductsQueryDto } from './dto/merchant-products-query.dto';
import { matchingProductIds } from './merchant.queries';
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

  /**
   * La carta del negocio para Socios: los conteos de cada pestaña (de toda la
   * carta) y los productos del filtro y la búsqueda, agrupados por sección en
   * el orden del menú. Los que no tienen sección van al final, en "Otros".
   */
  async products(storeId: string, query: MerchantProductsQueryDto, ownerId?: string) {
    const store = await this.prisma.store.findFirst({
      where: { id: storeId, ...ownedStores(ownerId) },
      select: { city: { select: { currency: true } } },
    });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');

    const where = { storeId, deletedAt: null };
    const [available, soldOut, matching] = await Promise.all([
      this.prisma.product.count({ where: { ...where, isAvailable: true } }),
      this.prisma.product.count({ where: { ...where, isAvailable: false } }),
      query.q ? matchingProductIds(this.prisma, storeId, query.q) : null,
    ]);
    const products = await this.prisma.product.findMany({
      where: {
        ...where,
        ...(query.status !== 'all' && { isAvailable: query.status === 'available' }),
        ...(matching && { id: { in: [...matching] } }),
      },
      orderBy: [{ menuSection: { sortOrder: 'asc' } }, { sortOrder: 'asc' }, { name: 'asc' }],
      include: { ...productCardInclude, menuSection: { select: { name: true } } },
    });

    const sections: { name: string; items: unknown[] }[] = [];
    const others: unknown[] = [];
    for (const product of products) {
      const item = {
        id: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        price: money(fromPrice(product), store.city.currency),
        section: product.menuSection?.name ?? null,
        isAvailable: product.isAvailable,
      };
      if (!item.section) {
        others.push(item);
        continue;
      }
      const last = sections.at(-1);
      if (last?.name === item.section) last.items.push(item);
      else sections.push({ name: item.section, items: [item] });
    }
    if (others.length > 0) sections.push({ name: 'Otros', items: others });

    return { counts: { all: available + soldOut, available, soldOut }, sections };
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
      select: {
        status: true,
        subtotal: true,
        createdAt: true,
        acceptedAt: true,
        readyAt: true,
        paymentMethod: true,
        payment: { select: { collectedMethod: true } },
        items: { select: { productId: true, productName: true, quantity: true, subtotal: true } },
      },
    });
    const s = summarizeMerchantDay(
      orders.map(({ payment, ...order }) => ({ ...order, collectedMethod: payment?.collectedMethod ?? null })),
      (at) => Math.floor(zonedTime.localTime(at, DEFAULT_TIMEZONE).minutes / 60),
    );
    return {
      date: day,
      deliveredCount: s.deliveredCount,
      cancelledCount: s.cancelledCount,
      activeCount: s.activeCount,
      sales: money(s.sales),
      averageTicket: s.averageTicket === null ? null : money(s.averageTicket),
      averagePrepMinutes: s.averagePrepMinutes,
      peakHour: s.peakHour,
      salesByHour: s.salesByHour.map((h) => ({ hour: h.hour, sales: money(h.sales), orders: h.orders })),
      payments: s.payments.map((p) => ({ method: p.method, sales: money(p.sales), orders: p.orders, share: p.share })),
      topProducts: s.topProducts.map((p) => ({
        productId: p.productId,
        name: p.name,
        quantity: p.quantity,
        sales: money(p.sales),
      })),
    };
  }
}
