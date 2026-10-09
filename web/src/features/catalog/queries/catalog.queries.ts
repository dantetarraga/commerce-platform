import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getCategories } from '../actions/categories.actions'
import { getStore } from '../actions/stores.actions'

export const categoriesQuery = queryOptions({
  queryKey: queryKeys.categories(),
  queryFn: ({ signal }) => getCategories(signal),
})

export const storeQuery = (id: string) =>
  queryOptions({
    queryKey: queryKeys.stores.detail(id),
    queryFn: ({ signal }) => getStore(id, signal),
  })
