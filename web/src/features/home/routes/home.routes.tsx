import type { QueryClient } from '@tanstack/react-query'
import { citiesQuery } from '@/app/api/lookups'
import { lastDays } from '@/lib/date-range'
import { AdminHomePage } from '../pages/admin-home.page'
import { analyticsQuery } from '../queries/analytics.queries'

export const adminHomeRoute = {
  path: '/',
  loader: ({ context: { queryClient } }: { context: { queryClient: QueryClient } }) => {
    void queryClient.prefetchQuery(citiesQuery)
    void queryClient.prefetchQuery(analyticsQuery({ ...lastDays(7), cityId: '' }))
  },
  component: AdminHomePage,
} as const
