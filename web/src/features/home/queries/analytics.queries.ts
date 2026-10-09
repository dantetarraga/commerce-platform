import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getAnalytics, type AnalyticsFilters } from '../actions/analytics.actions'

export const analyticsQuery = (filters: AnalyticsFilters) =>
  queryOptions({
    queryKey: queryKeys.analytics(filters),
    queryFn: ({ signal }) => getAnalytics(filters, signal),
    // El día en curso sigue sumando pedidos.
    refetchInterval: 5 * 60_000,
  })
