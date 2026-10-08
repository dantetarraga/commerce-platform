import { OrderStatus, PaymentMethodType } from '../../generated/prisma/enums';

/** Lo que el resumen necesita de cada pedido del día. */
export interface SummaryOrder {
  status: OrderStatus;
  subtotal: number;
  createdAt: Date;
  acceptedAt: Date | null;
  readyAt: Date | null;
  paymentMethod: PaymentMethodType;
  /** Cómo pagó de verdad (lo registra el repartidor al entregar). */
  collectedMethod: PaymentMethodType | null;
  items: readonly { productId: string | null; productName: string; quantity: number; subtotal: number }[];
}

export interface HourSales {
  /** Hora local, 0–23. */
  hour: number;
  sales: number;
  orders: number;
}

export interface PaymentSales {
  method: PaymentMethodType;
  sales: number;
  orders: number;
  /** Porcentaje entero de las ventas; los del día suman 100. */
  share: number;
}

export interface ProductSales {
  productId: string | null;
  name: string;
  quantity: number;
  sales: number;
}

export interface MerchantDaySummary {
  deliveredCount: number;
  cancelledCount: number;
  activeCount: number;
  /** Céntimos: suma del `subtotal` de los entregados (el envío es del repartidor). */
  sales: number;
  /** Céntimos por pedido entregado; `null` sin entregas. */
  averageTicket: number | null;
  /** De aceptado a listo, en minutos; `null` si ninguno llegó a listo. */
  averagePrepMinutes: number | null;
  /** Horas seguidas desde la primera hasta la última con ventas (las del medio en cero). */
  salesByHour: HourSales[];
  peakHour: number | null;
  /** Efectivo, Yape y Plin siempre, en ese orden; tarjeta solo si hubo. */
  payments: PaymentSales[];
  /** Los más vendidos por unidades. */
  topProducts: ProductSales[];
}

const PAYMENT_ORDER: PaymentMethodType[] = [
  PaymentMethodType.CASH,
  PaymentMethodType.YAPE,
  PaymentMethodType.PLIN,
  PaymentMethodType.CARD,
];

export const TOP_PRODUCTS = 5;

/**
 * Resumen del día del negocio a partir de los pedidos creados ese día. Las
 * ventas, las horas, los pagos y los productos cuentan solo los entregados.
 * [hourOf] da la hora local de un instante (la zona horaria la pone quien llama).
 */
export function summarizeMerchantDay(
  orders: readonly SummaryOrder[],
  hourOf: (at: Date) => number,
): MerchantDaySummary {
  const delivered = orders.filter((o) => o.status === OrderStatus.DELIVERED);
  const cancelledCount = orders.filter((o) => o.status === OrderStatus.CANCELLED).length;
  const sales = delivered.reduce((sum, o) => sum + o.subtotal, 0);

  return {
    deliveredCount: delivered.length,
    cancelledCount,
    activeCount: orders.length - delivered.length - cancelledCount,
    sales,
    averageTicket: delivered.length > 0 ? Math.round(sales / delivered.length) : null,
    averagePrepMinutes: averagePrepMinutes(orders),
    ...byHour(delivered, hourOf),
    payments: byPayment(delivered, sales),
    topProducts: topProducts(delivered),
  };
}

function averagePrepMinutes(orders: readonly SummaryOrder[]): number | null {
  const minutes = orders.flatMap((o) =>
    o.acceptedAt && o.readyAt && o.readyAt >= o.acceptedAt
      ? [(o.readyAt.getTime() - o.acceptedAt.getTime()) / 60_000]
      : [],
  );
  if (minutes.length === 0) return null;
  return Math.round(minutes.reduce((a, b) => a + b, 0) / minutes.length);
}

function byHour(delivered: readonly SummaryOrder[], hourOf: (at: Date) => number) {
  const totals = new Map<number, HourSales>();
  for (const order of delivered) {
    const hour = hourOf(order.createdAt);
    const slot = totals.get(hour) ?? { hour, sales: 0, orders: 0 };
    slot.sales += order.subtotal;
    slot.orders++;
    totals.set(hour, slot);
  }
  if (totals.size === 0) return { salesByHour: [], peakHour: null };
  const hours = [...totals.keys()];
  const salesByHour: HourSales[] = [];
  for (let hour = Math.min(...hours); hour <= Math.max(...hours); hour++) {
    salesByHour.push(totals.get(hour) ?? { hour, sales: 0, orders: 0 });
  }
  // Empate: la hora más temprana.
  const peak = salesByHour.reduce((best, slot) => (slot.sales > best.sales ? slot : best));
  return { salesByHour, peakHour: peak.hour };
}

function byPayment(delivered: readonly SummaryOrder[], total: number): PaymentSales[] {
  const rows = PAYMENT_ORDER.map((method) => {
    const paid = delivered.filter((o) => (o.collectedMethod ?? o.paymentMethod) === method);
    return { method, sales: paid.reduce((sum, o) => sum + o.subtotal, 0), orders: paid.length, share: 0 };
  }).filter((row) => row.method !== PaymentMethodType.CARD || row.orders > 0);
  if (total === 0) return rows;

  // Mayor resto: los porcentajes enteros suman exactamente 100.
  const exact = rows.map((row) => (row.sales * 100) / total);
  rows.forEach((row, i) => (row.share = Math.floor(exact[i])));
  const missing = 100 - rows.reduce((sum, row) => sum + row.share, 0);
  [...rows.keys()]
    .sort((a, b) => exact[b] - Math.floor(exact[b]) - (exact[a] - Math.floor(exact[a])))
    .slice(0, missing)
    .forEach((i) => rows[i].share++);
  return rows;
}

function topProducts(delivered: readonly SummaryOrder[]): ProductSales[] {
  const totals = new Map<string, ProductSales>();
  for (const item of delivered.flatMap((o) => o.items)) {
    // Un producto borrado del menú conserva su nombre en el pedido.
    const key = item.productId ?? `name:${item.productName}`;
    const row = totals.get(key) ?? { productId: item.productId, name: item.productName, quantity: 0, sales: 0 };
    row.quantity += item.quantity;
    row.sales += item.subtotal;
    totals.set(key, row);
  }
  return [...totals.values()]
    .sort((a, b) => b.quantity - a.quantity || b.sales - a.sales || a.name.localeCompare(b.name, 'es'))
    .slice(0, TOP_PRODUCTS);
}
