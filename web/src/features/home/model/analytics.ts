import type { Money } from '@/lib/money'

export type PaymentMethod = 'CASH' | 'YAPE' | 'PLIN' | 'CARD'
export type CancelledBy = 'CUSTOMER' | 'MERCHANT' | 'COURIER' | 'ADMIN' | 'SYSTEM'

export interface Kpis {
  orders: number
  delivered: number
  cancelled: number
  gmv: Money
  sales: Money
  avgTicket: Money
  customers: number
  newCustomers: number
}

/** `GET admin/analytics`: todo viene calculado; aquí solo se dibuja. */
export interface Analytics {
  from: string
  to: string
  previousFrom: string
  previousTo: string
  kpis: Kpis
  previous: Kpis
  byDay: { date: string; orders: number; delivered: number; cancelled: number; gmv: Money }[]
  byHour: { hour: number; orders: number }[]
  byWeekday: { dayOfWeek: number; orders: number }[]
  cancellations: {
    byWho: { who: CancelledBy; orders: number }[]
    reasons: { reason: string; orders: number }[]
  }
  times: {
    response: number | null
    preparation: number | null
    delivery: number | null
    total: number | null
  }
  topStores: { id: string; name: string; orders: number; sales: Money }[]
  topProducts: { name: string; quantity: number; sales: Money }[]
  topCouriers: { id: string; name: string; deliveries: number; minutes: number | null }[]
  payments: { method: PaymentMethod; orders: number; amount: Money }[]
  coupons: { code: string; orders: number; discount: Money }[]
}

export const CANCELLED_BY_LABEL: Record<CancelledBy, string> = {
  CUSTOMER: 'El cliente',
  MERCHANT: 'El negocio',
  COURIER: 'El repartidor',
  ADMIN: 'Apamuy',
  SYSTEM: 'Sin respuesta (8 min)',
}

export const PAYMENT_LABEL: Record<PaymentMethod, string> = {
  CASH: 'Efectivo',
  YAPE: 'Yape',
  PLIN: 'Plin',
  CARD: 'Tarjeta',
}

/** 0 = domingo, como el backend. */
export const WEEKDAY_LABEL = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb']

export const minutesLabel = (minutes: number | null) => (minutes === null ? '—' : `${minutes} min`)
