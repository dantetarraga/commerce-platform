import { OrderStatus, Role } from '../../generated/prisma/enums';
import { orderNotice } from '../notifications/order-notices';
import type { PushMessage } from './push-sender';

/** A quién va cada push: el cliente, el dueño del negocio o los repartidores libres de la ciudad. */
export type PushAudience = 'customer' | 'owner' | 'couriers';

export interface OrderPush {
  audience: PushAudience;
  message: PushMessage;
}

export interface PushOrder {
  id: string;
  code: string;
  storeId: string;
  storeName: string;
  cancelReason: string | null;
  cancelledBy: Role | null;
  courier: { firstName: string; vehicleLabel: string } | null;
}

/** El negocio tiene 8 minutos para responder: después la alarma ya no sirve. */
const ALARM_TTL_SECONDS = 8 * 60;
/** Un pedido listo sin repartidor deja de ser noticia en 10 minutos (se ve en la app). */
const READY_TTL_SECONDS = 10 * 60;

/** Los push que salen cuando un pedido pasa a [status]. */
export function orderPushes(order: PushOrder, status: OrderStatus): OrderPush[] {
  const pushes: OrderPush[] = [];

  // Al cliente, el mismo aviso que ve en la app (si no fue él quien canceló).
  const notice =
    status === OrderStatus.CANCELLED && order.cancelledBy === Role.CUSTOMER
      ? null
      : orderNotice(status, {
          orderId: order.id,
          code: order.code,
          storeId: order.storeId,
          storeName: order.storeName,
          courier: order.courier,
          cancelReason: order.cancelReason,
        });
  if (notice) {
    pushes.push({
      audience: 'customer',
      message: {
        title: notice.title,
        body: notice.body,
        data: { kind: notice.data.kind, orderId: order.id },
        channel: 'orders',
      },
    });
  }

  if (status === OrderStatus.RECEIVED) {
    // Solo datos: la app de Socios la muestra con la alarma que suena hasta que la atiendan.
    pushes.push({
      audience: 'owner',
      message: {
        data: {
          type: 'NEW_ORDER',
          orderId: order.id,
          code: order.code,
          title: 'Pedido nuevo',
          body: `${order.code} · ${order.storeName}. Acéptalo en la app.`,
        },
        channel: 'order_alarm',
        ttlSeconds: ALARM_TTL_SECONDS,
      },
    });
  }

  // Si lo canceló el cliente o Apamuy, el negocio tiene que saber que ya no lo prepare.
  if (status === OrderStatus.CANCELLED && order.cancelledBy !== Role.MERCHANT) {
    pushes.push({
      audience: 'owner',
      message: {
        title: 'Pedido cancelado',
        body: `${order.code}: ${order.cancelReason ?? 'se canceló'}. No lo prepares.`,
        data: { type: 'ORDER_CANCELLED', orderId: order.id },
        channel: 'orders',
      },
    });
  }

  if (status === OrderStatus.READY) {
    pushes.push({
      audience: 'couriers',
      message: {
        title: 'Pedido listo para recoger',
        body: `${order.storeName} · ${order.code}`,
        data: { type: 'ORDER_READY', orderId: order.id },
        channel: 'orders',
        ttlSeconds: READY_TTL_SECONDS,
      },
    });
  }

  return pushes;
}
