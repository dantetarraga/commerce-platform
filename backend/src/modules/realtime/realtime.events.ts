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

export interface CourierMovedEvent {
  orderId: string;
  lat: number;
  lng: number;
  at: Date;
}
