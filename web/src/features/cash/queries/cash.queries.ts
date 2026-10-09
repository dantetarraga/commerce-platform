import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getCashDay } from '../actions/cash.actions'
import type { CashFilters } from '../model/cash'

export const cashDayQuery = (filters: CashFilters) =>
  queryOptions({
    queryKey: queryKeys.cash(filters),
    queryFn: ({ signal }) => getCashDay(filters, signal),
  })
