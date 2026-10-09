import type { Money } from '@/lib/money'

export type PaymentMethod = 'CASH' | 'YAPE' | 'PLIN' | 'CARD'

export const PAYMENT_LABEL: Record<PaymentMethod, string> = {
  CASH: 'Efectivo',
  YAPE: 'Yape',
  PLIN: 'Plin',
  CARD: 'Tarjeta',
}

/** Indicadores comunes al resumen del día y al reporte de un rango. */
export interface SalesSummary {
  deliveredCount: number
  cancelledCount: number
  activeCount: number
  sales: Money
  averageTicket: Money | null
  averagePrepMinutes: number | null
  peakHour: number | null
  salesByHour: { hour: number; sales: Money; orders: number }[]
  payments: { method: PaymentMethod; sales: Money; orders: number; share: number }[]
  topProducts: { productId: string | null; name: string; quantity: number; sales: Money }[]
}

/** `GET merchant/summary`. */
export interface DaySummary extends SalesSummary {
  date: string
}

/** `GET merchant/reports`. */
export interface SalesReport extends SalesSummary {
  from: string
  to: string
  salesByDay: { date: string; sales: Money; delivered: number; cancelled: number }[]
  previous: {
    from: string
    to: string
    sales: Money
    deliveredCount: number
    cancelledCount: number
  }
}

export interface Collected {
  total: Money
  CASH: Money
  YAPE: Money
  PLIN: Money
}

/** `GET merchant/settlement`. */
export interface Settlement {
  from: string
  to: string
  delivered: number
  sales: Money
  collected: Collected
  /** Pendiente de definir (OPERACION §4): hoy siempre `null`. */
  commission: null
  days: { date: string; delivered: number; sales: Money; collected: Collected }[]
}
