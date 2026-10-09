import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getCategories } from '../actions/categories.actions'
import { getStore } from '../actions/stores.actions'
import type { CatalogScope } from '../model/catalog-scope'

export const categoriesQuery = queryOptions({
  queryKey: queryKeys.categories(),
  queryFn: ({ signal }) => getCategories(signal),
})

export const storeQuery = (id: string, scope: CatalogScope = 'admin') =>
  queryOptions({
    queryKey: queryKeys.stores.detail(id),
    queryFn: ({ signal }) => getStore(id, scope, signal),
  })
