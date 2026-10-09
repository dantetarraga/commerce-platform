import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  createProduct,
  deleteProduct,
  updateProduct,
  type ProductPayload,
} from '../actions/products.actions'

// La lista de negocios muestra cuántos productos tiene cada uno.
const refreshStore = (client: QueryClient, storeId: string) =>
  Promise.all([
    client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
    client.invalidateQueries({ queryKey: queryKeys.stores.list() }),
  ])

export const saveProductMutation = (storeId: string, productId?: string) =>
  mutationOptions({
    mutationFn: (payload: ProductPayload) =>
      productId ? updateProduct(productId, payload) : createProduct(storeId, payload),
    onSuccess: (_data, _payload, _result, { client }) => refreshStore(client, storeId),
  })

export const deleteProductMutation = (storeId: string, productId: string) =>
  mutationOptions({
    mutationFn: () => deleteProduct(productId),
    onSuccess: (_data, _vars, _result, { client }) => refreshStore(client, storeId),
  })
