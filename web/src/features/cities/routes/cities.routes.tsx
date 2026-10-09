import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { adminCitiesQuery } from '../queries/cities.queries'

export const citiesRoute = {
  path: 'cities',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(adminCitiesQuery)
  },
  component: lazyRouteComponent(() => import('../pages/cities.page'), 'CitiesPage'),
} as const
