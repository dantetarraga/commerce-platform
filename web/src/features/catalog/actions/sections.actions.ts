import { http } from '@/app/api'
import { catalogBase, type CatalogScope } from '../model/catalog-scope'
import type { SectionForm } from '../schemas/catalog.schemas'

export async function createSection(storeId: string, values: SectionForm, scope: CatalogScope) {
  await http.post(`${catalogBase(scope)}/stores/${storeId}/sections`, values)
}

export async function updateSection(id: string, values: SectionForm, scope: CatalogScope) {
  await http.patch(`${catalogBase(scope)}/sections/${id}`, values)
}

export async function deleteSection(id: string, scope: CatalogScope) {
  await http.delete(`${catalogBase(scope)}/sections/${id}`)
}
