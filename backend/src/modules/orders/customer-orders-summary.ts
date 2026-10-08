import { OrderStatus } from '../../generated/prisma/enums';

/** Negocios para "Volver a pedir". */
export const REPEAT_STORES = 8;

export interface SummaryInput {
  id: string;
  storeId: string;
  status: OrderStatus;
  discountTotal: number;
}

export interface CustomerOrdersSummary<T> {
  orderCount: number;
  activeCount: number;
  /** Céntimos ahorrados con cupones. */
  saved: number;
  latestOrderId: string | null;
  /** El último entregado de cada negocio (hasta [REPEAT_STORES]) y cuántas veces se le pidió. */
  repeat: { order: T; deliveredCount: number }[];
}

const FINAL: OrderStatus[] = [OrderStatus.DELIVERED, OrderStatus.CANCELLED];

/** Resumen de los pedidos del cliente. [orders] va del más reciente al más antiguo. */
export function summarizeCustomerOrders<T extends SummaryInput>(orders: readonly T[]): CustomerOrdersSummary<T> {
  const delivered = orders.filter((o) => o.status === OrderStatus.DELIVERED);
  const counts = new Map<string, number>();
  for (const order of delivered) counts.set(order.storeId, (counts.get(order.storeId) ?? 0) + 1);

  const seen = new Set<string>();
  const repeat: { order: T; deliveredCount: number }[] = [];
  for (const order of delivered) {
    if (seen.has(order.storeId)) continue;
    seen.add(order.storeId);
    repeat.push({ order, deliveredCount: counts.get(order.storeId) ?? 0 });
    if (repeat.length === REPEAT_STORES) break;
  }

  return {
    orderCount: orders.length,
    activeCount: orders.filter((o) => !FINAL.includes(o.status)).length,
    saved: orders.reduce((sum, o) => sum + o.discountTotal, 0),
    latestOrderId: orders[0]?.id ?? null,
    repeat,
  };
}
