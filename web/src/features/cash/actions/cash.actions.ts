import { http } from '@/app/api'
import type { CashDay, CashFilters } from '../model/cash'

export async function getCashDay({ date, cityId }: CashFilters, signal?: AbortSignal) {
  const params = { date, ...(cityId && { cityId }) }
  return (await http.get<CashDay>('/admin/cash', { params, signal })).data
}
