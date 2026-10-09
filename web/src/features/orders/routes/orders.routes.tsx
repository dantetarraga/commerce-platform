import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { citiesQuery } from '@/app/api/lookups'
import { ordersBoardQuery } from '../queries/orders.queries'

export const ordersRoute = {
  path: 'orders',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(citiesQuery)
    void queryClient.prefetchQuery(ordersBoardQuery(''))
  },
  component: lazyRouteComponent(() => import('../pages/orders.page'), 'OrdersPage'),
} as const
