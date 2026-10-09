import { http } from '@/app/api'
import type { DateRange } from '@/lib/date-range'
import type { Analytics } from '../model/analytics'

export interface AnalyticsFilters extends DateRange {
  /** Vacío: todas las ciudades. */
  cityId: string
}

export async function getAnalytics({ cityId, ...range }: AnalyticsFilters, signal?: AbortSignal) {
  const params = { ...range, ...(cityId && { cityId }) }
  return (await http.get<Analytics>('/admin/analytics', { params, signal })).data
}
