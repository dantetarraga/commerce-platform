import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { dateTime } from '@/lib/datetime'
import { cashDayQuery } from '../queries/cash.queries'

export const cashRoute = {
  path: 'cash',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(cashDayQuery({ date: dateTime.toApiDate(), cityId: '' }))
  },
  component: lazyRouteComponent(() => import('../pages/cash.page'), 'CashPage'),
} as const
