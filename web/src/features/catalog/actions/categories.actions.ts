import { http } from '@/app/api'
import type { Category } from '../model/catalog'

export interface CategoryPayload {
  name: string
  iconUrl: string | null
}

export async function getCategories(signal?: AbortSignal) {
  return (await http.get<Category[]>('/categories', { signal })).data
}

export async function createCategory(payload: CategoryPayload) {
  await http.post('/admin/categories', payload)
}

export async function updateCategory(id: string, payload: CategoryPayload) {
  await http.patch(`/admin/categories/${id}`, payload)
}
