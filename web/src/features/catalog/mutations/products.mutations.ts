import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  createProduct,
  deleteProduct,
  importProducts,
  updateProduct,
  type ProductPayload,
} from '../actions/products.actions'
import type { CatalogScope } from '../model/catalog-scope'
import type { ImportRow } from '../model/product-import'

// La lista de negocios muestra cuántos productos tiene cada uno.
const refreshStore = (client: QueryClient, storeId: string) =>
  Promise.all([
    client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
    client.invalidateQueries({ queryKey: queryKeys.stores.list() }),
  ])

export const saveProductMutation = (
  storeId: string,
  productId: string | undefined,
  scope: CatalogScope,
) =>
  mutationOptions({
    mutationFn: (payload: ProductPayload) =>
      productId ? updateProduct(productId, payload, scope) : createProduct(storeId, payload, scope),
    onSuccess: (_data, _payload, _result, { client }) => refreshStore(client, storeId),
  })

export const deleteProductMutation = (storeId: string, productId: string, scope: CatalogScope) =>
  mutationOptions({
    mutationFn: () => deleteProduct(productId, scope),
    onSuccess: (_data, _vars, _result, { client }) => refreshStore(client, storeId),
  })

/** Con `dryRun` solo revisa el archivo; la carta cambia cuando se confirma. */
export const importProductsMutation = (storeId: string, scope: CatalogScope) =>
  mutationOptions({
    mutationFn: ({ rows, dryRun }: { rows: ImportRow[]; dryRun: boolean }) =>
      importProducts(storeId, rows, dryRun, scope),
    onSuccess: (result, _vars, _result, { client }) =>
      result.dryRun ? undefined : refreshStore(client, storeId),
  })
