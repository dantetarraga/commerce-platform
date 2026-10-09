import { OrderStatus } from '../../../generated/prisma/enums';
import { OrderWithDetails, toStaffOrderResponse } from '../../orders/order-presenter';
import { responseAlert, waitingMinutes } from '../../orders/response-deadline';

/** Pedido para el tablero del admin: el de socios más tiempos, ciudad y quién canceló. */
export function toAdminOrder(order: OrderWithDetails, now: Date) {
  const unanswered = order.status === OrderStatus.RECEIVED;
  return {
    ...toStaffOrderResponse(order),
    cityId: order.cityId,
    storeId: order.storeId,
    couponCode: order.couponCode,
    acceptedAt: order.acceptedAt?.toISOString() ?? null,
    readyAt: order.readyAt?.toISOString() ?? null,
    deliveredAt: order.deliveredAt?.toISOString() ?? null,
    /** `null` con estado CANCELLED: lo canceló Apamuy porque el negocio no respondió. */
    cancelledBy: order.cancelledBy,
    /** Solo pedidos sin respuesta del negocio. */
    waitingMinutes: unanswered ? waitingMinutes(order, now) : null,
    alert: unanswered ? responseAlert(order, now) : null,
  };
}

export type AdminOrder = ReturnType<typeof toAdminOrder>;

/** Columnas del tablero en vivo, en orden. */
export const ADMIN_BOARD_COLUMNS = [
  { key: 'new', statuses: [OrderStatus.RECEIVED] },
  { key: 'kitchen', statuses: [OrderStatus.CONFIRMED, OrderStatus.PREPARING] },
  { key: 'pickup', statuses: [OrderStatus.READY] },
  { key: 'route', statuses: [OrderStatus.COURIER_ASSIGNED, OrderStatus.ON_THE_WAY] },
] as const;

/** Reparte los pedidos en curso; en "nuevos" primero el que más espera. */
export function groupAdminBoard(orders: readonly AdminOrder[]) {
  return ADMIN_BOARD_COLUMNS.map((column) => {
    const items = orders.filter((o) => (column.statuses as readonly OrderStatus[]).includes(o.status));
    if (column.key === 'new') items.sort((a, b) => (b.waitingMinutes ?? 0) - (a.waitingMinutes ?? 0));
    return { key: column.key, count: items.length, items };
  });
}
