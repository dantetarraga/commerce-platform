import { http } from '@/app/api'
import { catalogBase, type CatalogScope } from '../model/catalog-scope'
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
