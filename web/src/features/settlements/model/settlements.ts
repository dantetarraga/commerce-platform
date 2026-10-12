import type { WeekRange } from '@/components/shared/week-nav'
import type { Money } from '@/lib/money'

/** `OPEN`: la semana no terminó · `PENDING`: falta pagarla · `PAID`: ya se liquidó · `EMPTY`: sin entregas. */
export type SettlementStatus = 'OPEN' | 'PENDING' | 'PAID' | 'EMPTY'

/** Una semana de un negocio: vendido − comisión − lo que cobró el negocio = saldo. */
export interface StoreSettlement {
  storeId: string
  name: string
  delivered: number
  sales: Money
  commission: Money
  collectedByStore: Money
  /** > 0: Apamuy le paga al negocio; < 0: el negocio le paga a Apamuy. */
  balance: Money
  owedTo: 'STORE' | 'APAMUY' | null
  status: SettlementStatus
  paid: { at: string; by: { id: string; name: string } | null; balance: Money } | null
}

/** `GET admin/settlements?week&cityId` */
export interface SettlementWeek {
  week: WeekRange
  totals: {
    delivered: number
    sales: Money
    commission: Money
    collectedByStore: Money
    toStores: Money
    toApamuy: Money
    pendingCount: number
  }
  stores: StoreSettlement[]
}

/** `GET admin/commission` */
export interface CommissionSettings {
  rateBps: number
  updatedAt: string | null
  updatedBy: { id: string; name: string } | null
}

export interface SettlementFilters {
  week: string
  cityId: string
}

export const STATUS_LABEL: Record<SettlementStatus, string> = {
  OPEN: 'En curso',
  PENDING: 'Por pagar',
  PAID: 'Pagada',
  EMPTY: 'Sin ventas',
}
