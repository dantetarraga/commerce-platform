import { http } from '@/app/api'
import type { CommissionSettings, SettlementFilters, SettlementWeek } from '../model/settlements'

export async function getCommission(signal?: AbortSignal) {
  return (await http.get<CommissionSettings>('/admin/commission', { signal })).data
}

export async function setCommission(rateBps: number) {
  return (await http.put<CommissionSettings>('/admin/commission', { rateBps })).data
}

export async function getSettlementWeek({ week, cityId }: SettlementFilters, signal?: AbortSignal) {
  const params = { week, ...(cityId && { cityId }) }
  return (await http.get<SettlementWeek>('/admin/settlements', { params, signal })).data
}

export async function markSettlementPaid(storeId: string, week: string) {
  await http.post(`/admin/settlements/${storeId}/pay`, { week })
}
