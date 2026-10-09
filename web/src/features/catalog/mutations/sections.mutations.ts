import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { createSection, deleteSection, updateSection } from '../actions/sections.actions'
import type { SectionForm } from '../schemas/catalog.schemas'

export const saveSectionMutation = (storeId: string, sectionId?: string) =>
  mutationOptions({
    mutationFn: (values: SectionForm) =>
      sectionId ? updateSection(sectionId, values) : createSection(storeId, values),
    onSuccess: (_data, _values, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })

export const deleteSectionMutation = (storeId: string, sectionId: string) =>
  mutationOptions({
    mutationFn: () => deleteSection(sectionId),
    onSuccess: (_data, _vars, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })
