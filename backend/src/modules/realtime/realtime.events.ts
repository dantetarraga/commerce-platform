import type { OrderStatus } from '../../generated/prisma/enums';

/**
 * Eventos internos (`@nestjs/event-emitter`) que el gateway reenvía por
 * WebSocket. Se emiten después del commit.
 */
export const ORDER_CHANGED = 'order.changed';
export const COURIER_MOVED = 'courier.moved';

export interface OrderChangedEvent {
  orderId: string;
  storeId: string;
  cityId: string;
  status: OrderStatus;
}

/** [orderId] solo si va en camino con un pedido (lo ve ese cliente); el admin ve todos. */
export interface CourierMovedEvent {
  courierId: string;
  cityId: string;
  orderId: string | null;
  lat: number;
  lng: number;
  at: Date;
}
