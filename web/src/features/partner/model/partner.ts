import type { WeekRange } from '@/components/shared/week-nav'
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

/** `GET merchant/settlements/:storeId?week`: la liquidación de una semana (lunes a domingo). */
export interface WeeklySettlement {
  week: WeekRange
  storeId: string
  name: string
  delivered: number
  sales: Money
  commission: Money
  /** Lo que cobraste tú mismo; si cobró el repartidor, 0. */
  collectedByStore: Money
  /** > 0: Apamuy te paga; < 0: le pagas a Apamuy. */
  balance: Money
  owedTo: 'STORE' | 'APAMUY' | null
  /** `OPEN`: la semana no terminó · `PENDING`: falta pagarla · `PAID`: ya se liquidó · `EMPTY`: sin entregas. */
  status: 'OPEN' | 'PENDING' | 'PAID' | 'EMPTY'
  paid: { at: string; by: { id: string; name: string } | null; balance: Money } | null
  orders: {
    id: string
    code: string
    deliveredAt: string
    subtotal: Money
    rateBps: number
    commission: Money
    collectedByStore: Money
  }[]
}
