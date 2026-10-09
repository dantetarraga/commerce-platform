import type { Money } from '@/lib/money'

export interface Collected {
  total: Money
  CASH: Money
  YAPE: Money
  PLIN: Money
}

/** `GET admin/cash`: entregas de un día, por repartidor y por negocio. */
export interface CashDay {
  date: string
  delivered: number
  sales: Money
  deliveryFees: Money
  tips: Money
  /** Lo que los clientes debían pagar. */
  expected: Money
  collected: Collected
  /** Cobrado − esperado: negativo si falta plata o un cobro sin registrar. */
  difference: Money
  couriers: {
    courierId: string
    name: string
    phone: string
    delivered: number
    expected: Money
    collected: Collected
    difference: Money
  }[]
  stores: { storeId: string; name: string; delivered: number; sales: Money; collected: Collected }[]
}

export interface CashFilters {
  date: string
  cityId: string
}
