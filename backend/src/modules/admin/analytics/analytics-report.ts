import { OrderStatus, PaymentMethodType, Role } from '../../../generated/prisma/enums';

/** Un pedido del rango, con lo justo para las métricas del admin. */
export interface AnalyticsOrder {
  status: OrderStatus;
  /** Céntimos. */
  subtotal: number;
  total: number;
  discountTotal: number;
  createdAt: Date;
  acceptedAt: Date | null;
  readyAt: Date | null;
  deliveredAt: Date | null;
  scheduledFor: Date | null;
  cancelledBy: Role | null;
  cancelReason: string | null;
  customerId: string;
  storeId: string;
  storeName: string;
  couponCode: string | null;
  paymentMethod: PaymentMethodType;
  courier: { id: string; name: string } | null;
  items: { productName: string; quantity: number; subtotal: number }[];
}

export interface Kpis {
  orders: number;
  delivered: number;
  cancelled: number;
  /** Céntimos: total cobrado de los entregados (productos, envío y propina, menos descuentos). */
  gmv: number;
  /** Céntimos: subtotal de productos entregados. */
  sales: number;
  /** Céntimos por pedido entregado. */
  avgTicket: number;
  customers: number;
  newCustomers: number;
}

export interface AnalyticsReport {
  kpis: Kpis;
  previous: Kpis;
  byDay: { date: string; orders: number; delivered: number; cancelled: number; gmv: number }[];
  byHour: { hour: number; orders: number }[];
  byWeekday: { dayOfWeek: number; orders: number }[];
  cancellations: { byWho: { who: CancelledBy; orders: number }[]; reasons: { reason: string; orders: number }[] };
  /** Medianas en minutos; `null` si no hay pedidos para medirla. */
  times: { response: number | null; preparation: number | null; delivery: number | null; total: number | null };
  topStores: { id: string; name: string; orders: number; sales: number }[];
  topProducts: { name: string; quantity: number; sales: number }[];
  topCouriers: { id: string; name: string; deliveries: number; minutes: number | null }[];
  payments: { method: PaymentMethodType; orders: number; amount: number }[];
  coupons: { code: string; orders: number; discount: number }[];
}

/** Quién canceló: un rol o el sistema (8 min sin respuesta). */
export type CancelledBy = Role | 'SYSTEM';

const TOP = 5;
const minutesBetween = (from: Date | null, to: Date | null) =>
  from && to ? (to.getTime() - from.getTime()) / 60_000 : null;

export function median(values: readonly number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const value = sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  return Math.round(value);
}

const present = (values: (number | null)[]) => values.filter((v): v is number => v !== null && v >= 0);

/** [firstOrderAt]: primer pedido de cada cliente que pidió en el rango, para saber si es nuevo. */
export function kpis(orders: readonly AnalyticsOrder[], firstOrderAt: ReadonlyMap<string, Date>, start: Date): Kpis {
  const delivered = orders.filter((o) => o.status === OrderStatus.DELIVERED);
  const customers = new Set(orders.map((o) => o.customerId));
  const gmv = delivered.reduce((sum, o) => sum + o.total, 0);
  return {
    orders: orders.length,
    delivered: delivered.length,
    cancelled: orders.filter((o) => o.status === OrderStatus.CANCELLED).length,
    gmv,
    sales: delivered.reduce((sum, o) => sum + o.subtotal, 0),
    avgTicket: delivered.length ? Math.round(gmv / delivered.length) : 0,
    customers: customers.size,
    newCustomers: [...customers].filter((id) => (firstOrderAt.get(id)?.getTime() ?? 0) >= start.getTime()).length,
  };
}

function top<T>(rows: Map<string, T>, by: (row: T) => number): T[] {
  return [...rows.values()].sort((a, b) => by(b) - by(a)).slice(0, TOP);
}

/** Métricas del rango: [days] en orden, [dayOf] y [hourOf] en la hora de la ciudad. */
export function analyticsReport(input: {
  orders: readonly AnalyticsOrder[];
  previousOrders: readonly AnalyticsOrder[];
  firstOrderAt: ReadonlyMap<string, Date>;
  start: Date;
  previousStart: Date;
  days: readonly string[];
  dayOf: (at: Date) => string;
  hourOf: (at: Date) => number;
  weekdayOf: (at: Date) => number;
}): AnalyticsReport {
  const { orders, dayOf, hourOf, weekdayOf } = input;
  const delivered = orders.filter((o) => o.status === OrderStatus.DELIVERED);
  const cancelled = orders.filter((o) => o.status === OrderStatus.CANCELLED);

  const byDay = new Map(input.days.map((date) => [date, { date, orders: 0, delivered: 0, cancelled: 0, gmv: 0 }]));
  const byHour = Array.from({ length: 24 }, (_, hour) => ({ hour, orders: 0 }));
  const byWeekday = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, orders: 0 }));
  for (const order of orders) {
    const day = byDay.get(dayOf(order.createdAt));
    if (day) {
      day.orders++;
      if (order.status === OrderStatus.DELIVERED) {
        day.delivered++;
        day.gmv += order.total;
      } else if (order.status === OrderStatus.CANCELLED) {
        day.cancelled++;
      }
    }
    byHour[hourOf(order.createdAt)].orders++;
    byWeekday[weekdayOf(order.createdAt)].orders++;
  }

  const byWho = new Map<CancelledBy, number>();
  const reasons = new Map<string, { reason: string; orders: number }>();
  for (const order of cancelled) {
    const who = order.cancelledBy ?? 'SYSTEM';
    byWho.set(who, (byWho.get(who) ?? 0) + 1);
    const reason = order.cancelReason?.trim();
    if (reason) {
      const row = reasons.get(reason.toLowerCase()) ?? { reason, orders: 0 };
      row.orders++;
      reasons.set(reason.toLowerCase(), row);
    }
  }

  // Los programados esperan a propósito: no cuentan en preparación ni en el tiempo total.
  const onDemand = delivered.filter((o) => o.scheduledFor === null);

  const stores = new Map<string, { id: string; name: string; orders: number; sales: number }>();
  const products = new Map<string, { name: string; quantity: number; sales: number }>();
  const couriers = new Map<string, { id: string; name: string; deliveries: number; times: number[] }>();
  for (const order of delivered) {
    const store = stores.get(order.storeId) ?? { id: order.storeId, name: order.storeName, orders: 0, sales: 0 };
    store.orders++;
    store.sales += order.subtotal;
    stores.set(order.storeId, store);
    for (const item of order.items) {
      const key = `${order.storeId}:${item.productName}`;
      const product = products.get(key) ?? { name: item.productName, quantity: 0, sales: 0 };
      product.quantity += item.quantity;
      product.sales += item.subtotal;
      products.set(key, product);
    }
    if (order.courier) {
      const courier = couriers.get(order.courier.id) ?? { ...order.courier, deliveries: 0, times: [] };
      courier.deliveries++;
      const minutes = minutesBetween(order.readyAt, order.deliveredAt);
      if (minutes !== null) courier.times.push(minutes);
      couriers.set(order.courier.id, courier);
    }
  }

  const payments = new Map<PaymentMethodType, { method: PaymentMethodType; orders: number; amount: number }>();
  const coupons = new Map<string, { code: string; orders: number; discount: number }>();
  for (const order of delivered) {
    const payment = payments.get(order.paymentMethod) ?? { method: order.paymentMethod, orders: 0, amount: 0 };
    payment.orders++;
    payment.amount += order.total;
    payments.set(order.paymentMethod, payment);
    if (order.couponCode) {
      const coupon = coupons.get(order.couponCode) ?? { code: order.couponCode, orders: 0, discount: 0 };
      coupon.orders++;
      coupon.discount += order.discountTotal;
      coupons.set(order.couponCode, coupon);
    }
  }

  return {
    kpis: kpis(orders, input.firstOrderAt, input.start),
    previous: kpis(input.previousOrders, input.firstOrderAt, input.previousStart),
    byDay: [...byDay.values()],
    byHour,
    byWeekday,
    cancellations: {
      byWho: [...byWho].map(([who, count]) => ({ who, orders: count })).sort((a, b) => b.orders - a.orders),
      reasons: top(reasons, (r) => r.orders),
    },
    times: {
      response: median(present(orders.map((o) => minutesBetween(o.createdAt, o.acceptedAt)))),
      preparation: median(present(onDemand.map((o) => minutesBetween(o.acceptedAt, o.readyAt)))),
      delivery: median(present(delivered.map((o) => minutesBetween(o.readyAt, o.deliveredAt)))),
      total: median(present(onDemand.map((o) => minutesBetween(o.createdAt, o.deliveredAt)))),
    },
    topStores: top(stores, (s) => s.sales),
    topProducts: top(products, (p) => p.quantity),
    topCouriers: top(couriers, (c) => c.deliveries).map(({ times, ...courier }) => ({
      ...courier,
      minutes: median(times),
    })),
    payments: [...payments.values()].sort((a, b) => b.amount - a.amount),
    coupons: top(coupons, (c) => c.orders),
  };
}
