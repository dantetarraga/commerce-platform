import { OrderStatus } from '../../generated/prisma/enums';

/** Tipos de aviso que entiende la app (`NoticeKind`). */
export const NoticeKind = {
  ORDER_CONFIRMED: 'ORDER_CONFIRMED',
  PREPARING: 'PREPARING',
  COURIER_ASSIGNED: 'COURIER_ASSIGNED',
  COURIER_NEARBY: 'COURIER_NEARBY',
  DELIVERED: 'DELIVERED',
  ORDER_CANCELLED: 'ORDER_CANCELLED',
  PROMOTION: 'PROMOTION',
} as const;

export type NoticeKind = (typeof NoticeKind)[keyof typeof NoticeKind];

/** Lo que se guarda en `Notification.data`. */
export interface NoticeData {
  kind: NoticeKind;
  orderId?: string;
  storeId?: string;
}

export interface OrderNoticeInput {
  orderId: string;
  code: string;
  storeId: string;
  storeName: string;
  courier?: { firstName: string; vehicleLabel: string } | null;
  cancelReason?: string | null;
}

export interface OrderNotice {
  title: string;
  body: string;
  data: NoticeData;
}

/**
 * Aviso para el cliente cuando su pedido cambia de estado. `null` = ese paso
 * no avisa (p. ej. "listo en el negocio": el cliente espera al repartidor).
 */
export function orderNotice(to: OrderStatus, order: OrderNoticeInput): OrderNotice | null {
  const forOrder = (kind: NoticeKind): NoticeData => ({ kind, orderId: order.orderId });
  const courier = order.courier?.firstName ?? 'Tu repartidor';
  switch (to) {
    case OrderStatus.CONFIRMED:
      return {
        title: 'Pedido confirmado',
        body: `${order.storeName} recibió tu pedido ${order.code}`,
        data: forOrder(NoticeKind.ORDER_CONFIRMED),
      };
    case OrderStatus.PREPARING:
      return {
        title: '¡Ya están preparando tu pedido!',
        body: `${order.storeName} está preparando tu pedido ${order.code}`,
        data: forOrder(NoticeKind.PREPARING),
      };
    case OrderStatus.COURIER_ASSIGNED:
      return {
        title: `${courier} va por tu pedido`,
        body: order.courier ? `${order.courier.vehicleLabel} · lo recoge en ${order.storeName}` : order.storeName,
        data: forOrder(NoticeKind.COURIER_ASSIGNED),
      };
    case OrderStatus.ON_THE_WAY:
      return {
        title: `${courier} va en camino`,
        body: `Tu pedido de ${order.storeName} ya salió hacia tu dirección`,
        data: forOrder(NoticeKind.COURIER_NEARBY),
      };
    case OrderStatus.DELIVERED:
      return {
        title: 'Entregado',
        body: `${order.storeName} · ¿qué tal estuvo?`,
        // Al tocarlo lleva al negocio, para volver a pedir o calificar.
        data: { kind: NoticeKind.DELIVERED, orderId: order.orderId, storeId: order.storeId },
      };
    case OrderStatus.CANCELLED:
      return {
        title: 'Pedido cancelado',
        body: order.cancelReason
          ? `${order.storeName}: ${order.cancelReason}. No se te cobró nada.`
          : `Tu pedido ${order.code} de ${order.storeName} se canceló. No se te cobró nada.`,
        data: forOrder(NoticeKind.ORDER_CANCELLED),
      };
    default:
      return null;
  }
}
