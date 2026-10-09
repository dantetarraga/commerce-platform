import { Injectable } from '@nestjs/common';
import { DEFAULT_TIMEZONE, zonedTime } from '../../../common/time';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { eachDay, previousPeriod, rangeErrors } from '../../merchant/merchant-report';
import { invalid } from '../catalog/catalog-rules';
import { AnalyticsOrder, analyticsReport, Kpis } from './analytics-report';

const orderSelect = {
  status: true,
  subtotal: true,
  total: true,
  discountTotal: true,
  createdAt: true,
  acceptedAt: true,
  readyAt: true,
  deliveredAt: true,
  scheduledFor: true,
  cancelledBy: true,
  cancelReason: true,
  customerId: true,
  storeId: true,
  storeName: true,
  couponCode: true,
  paymentMethod: true,
  currency: true,
  courier: { select: { id: true, user: { select: { firstName: true, lastName: true } } } },
  items: { select: { productName: true, quantity: true, subtotal: true } },
} satisfies Prisma.OrderSelect;

type Row = Prisma.OrderGetPayload<{ select: typeof orderSelect }>;

const toAnalytics = (row: Row): AnalyticsOrder => ({
  ...row,
  courier: row.courier && {
    id: row.courier.id,
    name: `${row.courier.user.firstName} ${row.courier.user.lastName.charAt(0)}.`.trim(),
  },
});

@Injectable()
export class AdminAnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async report(from: string, to: string, cityId?: string) {
    const errors = rangeErrors(from, to);
    if (Object.keys(errors).length > 0) throw invalid(errors);
    const timezone = cityId
      ? ((await this.prisma.city.findUnique({ where: { id: cityId }, select: { timezone: true } }))?.timezone ??
        DEFAULT_TIMEZONE)
      : DEFAULT_TIMEZONE;
    const range = (a: string, b: string) => ({
      start: zonedTime.dayRange(a, timezone).start,
      end: zonedTime.dayRange(b, timezone).end,
    });
    const current = range(from, to);
    const before = previousPeriod(from, to);
    const previous = range(before.from, before.to);
    const [rows, previousRows] = await Promise.all([
      this.orders(current.start, current.end, cityId),
      this.orders(previous.start, previous.end, cityId),
    ]);
    const customers = [...new Set([...rows, ...previousRows].map((o) => o.customerId))];
    const firsts = await this.prisma.order.groupBy({
      by: ['customerId'],
      where: { customerId: { in: customers } },
      _min: { createdAt: true },
    });
    const firstOrderAt = new Map(firsts.map((f) => [f.customerId, f._min.createdAt ?? new Date(0)]));

    const report = analyticsReport({
      orders: rows.map(toAnalytics),
      previousOrders: previousRows.map(toAnalytics),
      firstOrderAt,
      start: current.start,
      previousStart: previous.start,
      days: eachDay(from, to),
      dayOf: (at) => zonedTime.localDate(at, timezone),
      hourOf: (at) => Math.floor(zonedTime.localTime(at, timezone).minutes / 60),
      weekdayOf: (at) => zonedTime.localTime(at, timezone).dayOfWeek,
    });

    const currency = rows[0]?.currency ?? previousRows[0]?.currency ?? 'PEN';
    const m = (amount: number) => money(amount, currency);
    const kpis = (k: Kpis) => ({ ...k, gmv: m(k.gmv), sales: m(k.sales), avgTicket: m(k.avgTicket) });
    return {
      from,
      to,
      previousFrom: before.from,
      previousTo: before.to,
      kpis: kpis(report.kpis),
      previous: kpis(report.previous),
      byDay: report.byDay.map((d) => ({ ...d, gmv: m(d.gmv) })),
      byHour: report.byHour,
      byWeekday: report.byWeekday,
      cancellations: report.cancellations,
      times: report.times,
      topStores: report.topStores.map((s) => ({ ...s, sales: m(s.sales) })),
      topProducts: report.topProducts.map((p) => ({ ...p, sales: m(p.sales) })),
      topCouriers: report.topCouriers,
      payments: report.payments.map((p) => ({ ...p, amount: m(p.amount) })),
      coupons: report.coupons.map((c) => ({ ...c, discount: m(c.discount) })),
    };
  }

  private orders(start: Date, end: Date, cityId?: string) {
    return this.prisma.order.findMany({
      where: { createdAt: { gte: start, lt: end }, ...(cityId && { cityId }) },
      select: orderSelect,
    });
  }
}
