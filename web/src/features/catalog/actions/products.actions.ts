import { http } from '@/app/api'
import { catalogBase, type CatalogScope } from '../model/catalog-scope'
import type { ImportResult, ImportRow } from '../model/product-import'
import type { productPayload } from '../schemas/catalog.schemas'

export type ProductPayload = ReturnType<typeof productPayload>

export async function createProduct(storeId: string, payload: ProductPayload, scope: CatalogScope) {
  await http.post(`${catalogBase(scope)}/stores/${storeId}/products`, payload)
}

export async function updateProduct(id: string, payload: ProductPayload, scope: CatalogScope) {
  await http.patch(`${catalogBase(scope)}/products/${id}`, payload)
}

export async function deleteProduct(id: string, scope: CatalogScope) {
  await http.delete(`${catalogBase(scope)}/products/${id}`)
}

export async function importProducts(
  storeId: string,
  rows: ImportRow[],
  dryRun: boolean,
  scope: CatalogScope,
) {
  const { data } = await http.post<ImportResult>(
    `${catalogBase(scope)}/stores/${storeId}/products/import`,
    { rows, dryRun },
    // Hasta 500 filas en una transacción.
    { timeout: 60_000 },
  )
  return data
}
