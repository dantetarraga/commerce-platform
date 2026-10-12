import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getCommission, getSettlementWeek } from '../actions/settlements.actions'
import type { SettlementFilters } from '../model/settlements'

export const commissionQuery = queryOptions({
  queryKey: queryKeys.commission(),
  queryFn: ({ signal }) => getCommission(signal),
})

export const settlementWeekQuery = (filters: SettlementFilters) =>
  queryOptions({
    queryKey: queryKeys.settlements.week(filters),
    queryFn: ({ signal }) => getSettlementWeek(filters, signal),
  })
