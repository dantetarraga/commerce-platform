import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { dateTime } from '@/lib/datetime'
import { commissionQuery, settlementWeekQuery } from '../queries/settlements.queries'

export const settlementsRoute = {
  path: 'settlements',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(commissionQuery)
    void queryClient.prefetchQuery(settlementWeekQuery({ week: dateTime.toApiDate(), cityId: '' }))
  },
  component: lazyRouteComponent(() => import('../pages/settlements.page'), 'SettlementsPage'),
} as const
