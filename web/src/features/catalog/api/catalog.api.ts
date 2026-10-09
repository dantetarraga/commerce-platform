import { queryOptions, useMutation, useQueryClient } from '@tanstack/react-query'
import { http } from '@/app/api'
import type { Category, StoreDetail } from '../model/catalog'

export const categoriesQuery = queryOptions({
  queryKey: ['categories'],
  queryFn: async ({ signal }) => (await http.get<Category[]>('/categories', { signal })).data,
})

export const storeQuery = (id: string) =>
  queryOptions({
    queryKey: ['admin', 'stores', id],
    queryFn: async ({ signal }) =>
      (await http.get<StoreDetail>(`/admin/stores/${id}`, { signal })).data,
  })

export function useCatalogMutation<T, R = unknown>(mutationFn: (values: T) => Promise<R>) {
  const client = useQueryClient()
  return useMutation({
    mutationFn,
    onSuccess: async () => {
      await Promise.all([
        client.invalidateQueries({ queryKey: ['admin', 'stores'] }),
        client.invalidateQueries({ queryKey: ['categories'] }),
        client.invalidateQueries({ queryKey: ['admin', 'partners'] }),
      ])
    },
  })
}
