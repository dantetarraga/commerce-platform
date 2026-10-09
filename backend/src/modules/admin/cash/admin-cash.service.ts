import { Injectable } from '@nestjs/common';
import { DEFAULT_TIMEZONE, zonedTime } from '../../../common/time';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { OrderStatus } from '../../../generated/prisma/enums';
import type { CollectedTotals } from '../../couriers/courier-summary';
import { cashReport } from './cash-report';

const collectedJson = (totals: CollectedTotals) => ({
  total: money(totals.total),
  CASH: money(totals.CASH),
  YAPE: money(totals.YAPE),
  PLIN: money(totals.PLIN),
});

/** Caja del día: lo que cobró cada repartidor y lo que vendió cada negocio. */
@Injectable()
export class AdminCashService {
  constructor(private readonly prisma: PrismaService) {}

  async day(date: string | undefined, cityId: string | undefined, now = new Date()) {
    const day = date ?? zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const { start, end } = zonedTime.dayRange(day, DEFAULT_TIMEZONE);
    const orders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        deliveredAt: { gte: start, lt: end },
        ...(cityId && { cityId }),
      },
      select: {
        storeId: true,
        storeName: true,
        subtotal: true,
        deliveryFee: true,
        tip: true,
        total: true,
        courier: { select: { id: true, user: { select: { firstName: true, lastName: true, phone: true } } } },
        payment: { select: { collectedMethod: true, collectedAmount: true } },
      },
    });
    const report = cashReport(
      orders.map(({ courier, payment, ...order }) => ({
        ...order,
        courier: courier && {
          id: courier.id,
          name: `${courier.user.firstName} ${courier.user.lastName}`.trim(),
          phone: courier.user.phone,
        },
        collectedMethod: payment?.collectedMethod ?? null,
        collectedAmount: payment?.collectedAmount ?? null,
      })),
    );
    return {
      date: day,
      delivered: report.delivered,
      sales: money(report.sales),
      deliveryFees: money(report.deliveryFees),
      tips: money(report.tips),
      expected: money(report.expected),
      collected: collectedJson(report.collected),
      difference: money(report.difference),
      couriers: report.couriers.map((courier) => ({
        ...courier,
        expected: money(courier.expected),
        collected: collectedJson(courier.collected),
        difference: money(courier.difference),
      })),
      stores: report.stores.map((store) => ({
        ...store,
        sales: money(store.sales),
        collected: collectedJson(store.collected),
      })),
    };
  }
}
