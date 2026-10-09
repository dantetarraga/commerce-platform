import type { Money } from '@/lib/money'

export type OrderStatus =
  | 'RECEIVED'
  | 'CONFIRMED'
  | 'PREPARING'
  | 'READY'
  | 'COURIER_ASSIGNED'
  | 'ON_THE_WAY'
  | 'DELIVERED'
  | 'CANCELLED'

export type PaymentType = 'CASH' | 'YAPE' | 'PLIN' | 'CARD'

export interface LatLng {
  lat: number
  lng: number
}

/** Pedido de `admin/orders`: el de socios con tiempos, ciudad y alerta de respuesta. */
export interface AdminOrder {
  id: string
  code: string
  status: OrderStatus
  store: { id: string; name: string; logoUrl: string | null }
  lines: {
    productId: string | null
    name: string
    quantity: number
    total: Money
    description: string
    notes: string
  }[]
  subtotal: Money
  deliveryFee: Money
  discount: Money
  tip: Money
  total: Money
  notes: string | null
  address: { title: string; street: string; reference: string | null }
  payment: { type: PaymentType; changeFor: Money | null }
  events: { status: OrderStatus; at: string }[]
  placedAt: string
  courier: { name: string; vehicle: string } | null
  estimatedArrival: string | null
  scheduledFor: string | null
  customer: { name: string; phone: string }
  pickup: { address: string; phone: string | null; location: LatLng }
  distanceMeters: number
  cancelReason: string | null
  collection: { method: PaymentType; amount: Money; collectedAt: string } | null
  cityId: string
  storeId: string
  couponCode: string | null
  acceptedAt: string | null
  readyAt: string | null
  deliveredAt: string | null
  cancelledBy: 'CUSTOMER' | 'MERCHANT' | 'COURIER' | 'ADMIN' | null
  waitingMinutes: number | null
  alert: 'late' | null
}

export type BoardColumnKey = 'new' | 'kitchen' | 'pickup' | 'route'

export interface OrdersBoard {
  generatedAt: string
  columns: { key: BoardColumnKey; count: number; items: AdminOrder[] }[]
  lateCount: number
  today: { placed: number; delivered: number; cancelled: number; sales: Money }
}

export interface OrdersPage {
  items: AdminOrder[]
  nextCursor: string | null
}

export const BOARD_COLUMN_LABEL: Record<BoardColumnKey, { title: string; hint: string }> = {
  new: { title: 'Por confirmar', hint: 'Esperan que el negocio acepte' },
  kitchen: { title: 'En cocina', hint: 'Aceptados y en preparación' },
  pickup: { title: 'Listos', hint: 'Esperan al repartidor' },
  route: { title: 'En camino', hint: 'Con repartidor asignado' },
}

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  RECEIVED: 'Por confirmar',
  CONFIRMED: 'Aceptado',
  PREPARING: 'En cocina',
  READY: 'Listo para recoger',
  COURIER_ASSIGNED: 'Repartidor asignado',
  ON_THE_WAY: 'En camino',
  DELIVERED: 'Entregado',
  CANCELLED: 'Cancelado',
}

export const PAYMENT_LABEL: Record<PaymentType, string> = {
  CASH: 'Efectivo',
  YAPE: 'Yape',
  PLIN: 'Plin',
  CARD: 'Tarjeta',
}

const FINAL: OrderStatus[] = ['DELIVERED', 'CANCELLED']
export const isFinal = (status: OrderStatus) => FINAL.includes(status)

/** Quién canceló, en palabras. `null`: Apamuy, porque el negocio no respondió. */
export function cancelledByLabel(order: Pick<AdminOrder, 'cancelledBy'>): string {
  switch (order.cancelledBy) {
    case 'CUSTOMER':
      return 'el cliente'
    case 'MERCHANT':
      return 'el negocio'
    case 'COURIER':
      return 'el repartidor'
    case 'ADMIN':
      return 'el equipo Apamuy'
    case null:
      return 'Apamuy (sin respuesta del negocio)'
  }
}
