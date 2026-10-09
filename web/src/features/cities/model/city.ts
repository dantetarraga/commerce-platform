import type { Money } from '@/lib/money'

export interface FeeExample {
  straightKm: number
  streetKm: number
  fee: Money
  travelMinutes: number
}

/** Ciudad con sus parámetros de reparto, como la devuelve `GET admin/cities`. */
export interface AdminCity {
  id: string
  name: string
  region: string | null
  slug: string
  timezone: string
  currency: string
  centerLat: number
  centerLng: number
  coverageKm: number
  maxDeliveryKm: number
  baseDeliveryFee: Money
  feePerKm: Money
  routeFactor: number
  avgSpeedKmh: number
  isActive: boolean
  storeCount: number
  courierCount: number
  /** Calculados por el backend con la misma fórmula del cobro real. */
  feeExamples: FeeExample[]
}
