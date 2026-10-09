import { http } from '@/app/api'
import type { DateRange } from '@/lib/date-range'
import type { DaySummary, SalesReport, Settlement } from '../model/partner'

export async function getDaySummary(date: string, signal?: AbortSignal) {
  return (await http.get<DaySummary>('/merchant/summary', { params: { date }, signal })).data
}

export async function getSalesReport(range: DateRange, storeId: string, signal?: AbortSignal) {
  return (
    await http.get<SalesReport>('/merchant/reports', { params: { ...range, storeId }, signal })
  ).data
}

export async function getSettlement(range: DateRange, storeId: string, signal?: AbortSignal) {
  return (
    await http.get<Settlement>('/merchant/settlement', { params: { ...range, storeId }, signal })
  ).data
}
