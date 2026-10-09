import { http } from '@/app/api'
import type { productPayload } from '../schemas/catalog.schemas'

export type ProductPayload = ReturnType<typeof productPayload>

export async function createProduct(storeId: string, payload: ProductPayload) {
  await http.post(`/admin/stores/${storeId}/products`, payload)
}

export async function updateProduct(id: string, payload: ProductPayload) {
  await http.patch(`/admin/products/${id}`, payload)
}

export async function deleteProduct(id: string) {
  await http.delete(`/admin/products/${id}`)
}
