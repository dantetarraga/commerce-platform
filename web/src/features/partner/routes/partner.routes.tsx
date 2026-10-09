import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { ownStoresQuery } from '@/app/api/lookups'
import { dateTime } from '@/lib/datetime'
import { daySummaryQuery } from '../queries/partner.queries'

interface LoaderArgs {
  context: { queryClient: QueryClient }
}

export const partnerHomeRoute = {
  path: '/',
  loader: ({ context: { queryClient } }: LoaderArgs) => {
    void queryClient.prefetchQuery(daySummaryQuery(dateTime.toApiDate()))
  },
  component: lazyRouteComponent(() => import('../pages/partner-home.page'), 'PartnerHomePage'),
} as const

const prefetchOwnStores = ({ context: { queryClient } }: LoaderArgs) => {
  void queryClient.prefetchQuery(ownStoresQuery)
}

export const partnerReportsRoute = {
  path: 'reports',
  loader: prefetchOwnStores,
  component: lazyRouteComponent(
    () => import('../pages/partner-reports.page'),
    'PartnerReportsPage',
  ),
} as const

export const partnerSettlementRoute = {
  path: 'settlement',
  loader: prefetchOwnStores,
  component: lazyRouteComponent(
    () => import('../pages/partner-settlement.page'),
    'PartnerSettlementPage',
  ),
} as const
