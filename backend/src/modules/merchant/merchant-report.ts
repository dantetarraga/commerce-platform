import { OrderStatus, PaymentMethodType } from '../../generated/prisma/enums';
import { CollectedTotals, sumCollected } from '../couriers/courier-summary';

/** Rango máximo de un reporte: un trimestre. */
export const MAX_REPORT_DAYS = 92;

const DAY_MS = 24 * 60 * 60 * 1000;
const toUtc = (date: string) => Date.parse(`${date}T00:00:00Z`);
const fromUtc = (ms: number) => new Date(ms).toISOString().slice(0, 10);

/** Días `AAAA-MM-DD` de [from] a [to], ambos incluidos. */
export function eachDay(from: string, to: string): string[] {
  const days: string[] = [];
  for (let ms = toUtc(from); ms <= toUtc(to); ms += DAY_MS) days.push(fromUtc(ms));
  return days;
}

/** El periodo de la misma duración que termina el día antes de [from]. */
export function previousPeriod(from: string, to: string): { from: string; to: string } {
  const length = eachDay(from, to).length;
  return { from: fromUtc(toUtc(from) - length * DAY_MS), to: fromUtc(toUtc(from) - DAY_MS) };
}

/** Errores por campo del rango pedido, o vacío si sirve. */
export function rangeErrors(from: string, to: string): Record<string, string> {
  if (toUtc(to) < toUtc(from)) return { to: 'La fecha final debe ser igual o posterior a la inicial.' };
  if (eachDay(from, to).length > MAX_REPORT_DAYS) return { to: `El rango máximo es de ${MAX_REPORT_DAYS} días.` };
  return {};
}

export interface DaySales {
  date: string;
  /** Céntimos: subtotal de los entregados. */
  sales: number;
  delivered: number;
  cancelled: number;
}

/** Ventas y pedidos de cada día del rango, con ceros en los días sin pedidos. */
export function salesByDay(
  orders: readonly { status: OrderStatus; subtotal: number; createdAt: Date }[],
  days: readonly string[],
  dayOf: (at: Date) => string,
): DaySales[] {
  const rows = new Map(days.map((date) => [date, { date, sales: 0, delivered: 0, cancelled: 0 }]));
  for (const order of orders) {
    const row = rows.get(dayOf(order.createdAt));
    if (!row) continue;
    if (order.status === OrderStatus.DELIVERED) {
      row.sales += order.subtotal;
      row.delivered++;
    } else if (order.status === OrderStatus.CANCELLED) {
      row.cancelled++;
    }
  }
  return [...rows.values()];
}

export interface DaySettlement {
  date: string;
  delivered: number;
  /** Céntimos: lo que vendió el negocio (subtotales). */
  sales: number;
  /** Lo que el repartidor cobró al cliente, por método (incluye envío y propina). */
  collected: CollectedTotals;
}

/** Lo vendido y cobrado de los pedidos entregados, por día de entrega. */
export function settlementByDay(
  orders: readonly {
    subtotal: number;
    deliveredAt: Date;
    collectedMethod: PaymentMethodType | null;
    collectedAmount: number | null;
  }[],
  days: readonly string[],
  dayOf: (at: Date) => string,
): DaySettlement[] {
  return days.map((date) => {
    const delivered = orders.filter((order) => dayOf(order.deliveredAt) === date);
    return {
      date,
      delivered: delivered.length,
      sales: delivered.reduce((sum, order) => sum + order.subtotal, 0),
      collected: sumCollected(delivered),
    };
  });
}
