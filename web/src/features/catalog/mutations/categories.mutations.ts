import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { createCategory, updateCategory, type CategoryPayload } from '../actions/categories.actions'

export const saveCategoryMutation = (categoryId?: string) =>
  mutationOptions({
    mutationFn: (payload: CategoryPayload) =>
      categoryId ? updateCategory(categoryId, payload) : createCategory(payload),
    onSuccess: (_data, _payload, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.categories() }),
  })
