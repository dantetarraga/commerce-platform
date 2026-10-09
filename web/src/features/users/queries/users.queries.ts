import { infiniteQueryOptions, queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getUser, listUsers, type UsersFilters } from '../actions/users.actions'

export const usersQuery = (filters: UsersFilters) =>
  infiniteQueryOptions({
    queryKey: queryKeys.users.list(filters),
    queryFn: ({ pageParam, signal }) => listUsers(filters, pageParam, signal),
    initialPageParam: 1,
    getNextPageParam: (last) =>
      last.page * last.pageSize < last.total ? last.page + 1 : undefined,
  })

export const userQuery = (id: string) =>
  queryOptions({
    queryKey: queryKeys.users.detail(id),
    queryFn: ({ signal }) => getUser(id, signal),
  })
