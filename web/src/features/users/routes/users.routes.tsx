import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { userQuery, usersQuery } from '../queries/users.queries'

interface LoaderArgs {
  context: { queryClient: QueryClient }
}

export const usersRoute = {
  path: 'users',
  loader: ({ context: { queryClient } }: LoaderArgs) => {
    void queryClient.prefetchInfiniteQuery(usersQuery({ q: '', role: '', status: '' }))
  },
  component: lazyRouteComponent(() => import('../pages/users.page'), 'UsersPage'),
} as const

export const userDetailRoute = {
  path: 'users/$userId',
  loader: ({ context: { queryClient }, params }: LoaderArgs & { params: { userId: string } }) => {
    void queryClient.prefetchQuery(userQuery(params.userId))
  },
  component: lazyRouteComponent(() => import('../pages/user-detail.page'), 'UserDetailPage'),
} as const
