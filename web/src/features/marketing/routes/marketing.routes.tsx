import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { adminStoresQuery, citiesQuery } from '@/app/api/lookups'
import { couponsQuery, promotionsQuery } from '../queries/marketing.queries'

export const marketingRoute = {
  path: 'marketing',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(couponsQuery)
    void queryClient.prefetchQuery(citiesQuery)
    void queryClient.prefetchQuery(adminStoresQuery)
    void queryClient.prefetchQuery(promotionsQuery(''))
  },
  component: lazyRouteComponent(() => import('../pages/marketing.page'), 'MarketingPage'),
} as const
