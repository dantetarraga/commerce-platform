import { http } from '@/app/api'
import type { SectionForm } from '../schemas/catalog.schemas'

export async function createSection(storeId: string, values: SectionForm) {
  await http.post(`/admin/stores/${storeId}/sections`, values)
}

export async function updateSection(id: string, values: SectionForm) {
  await http.patch(`/admin/sections/${id}`, values)
}

export async function deleteSection(id: string) {
  await http.delete(`/admin/sections/${id}`)
}
