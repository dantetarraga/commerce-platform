import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { createSection, deleteSection, updateSection } from '../actions/sections.actions'
import type { CatalogScope } from '../model/catalog-scope'
import type { SectionForm } from '../schemas/catalog.schemas'

export const saveSectionMutation = (
  storeId: string,
  sectionId: string | undefined,
  scope: CatalogScope,
) =>
  mutationOptions({
    mutationFn: (values: SectionForm) =>
      sectionId ? updateSection(sectionId, values, scope) : createSection(storeId, values, scope),
    onSuccess: (_data, _values, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })

export const deleteSectionMutation = (storeId: string, sectionId: string, scope: CatalogScope) =>
  mutationOptions({
    mutationFn: () => deleteSection(sectionId, scope),
    onSuccess: (_data, _vars, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })
