import { http } from '@/app/api'
import type { Schedule, StoreDetail } from '../model/catalog'
import type { storePayload } from '../schemas/catalog.schemas'

export type StorePayload = ReturnType<typeof storePayload>
export type StoreUpdate = Omit<StorePayload, 'cityId'>

export async function getStore(id: string, signal?: AbortSignal) {
  return (await http.get<StoreDetail>(`/admin/stores/${id}`, { signal })).data
}

/** Los negocios nuevos nacen como borrador. */
export async function createStore(payload: StorePayload) {
  return (await http.post<StoreDetail>('/admin/stores', { ...payload, isActive: false })).data
}

export async function updateStore(id: string, update: StoreUpdate) {
  return (await http.patch<StoreDetail>(`/admin/stores/${id}`, update)).data
}

export async function setStorePublished(id: string, isActive: boolean) {
  return (await http.patch<StoreDetail>(`/admin/stores/${id}`, { isActive })).data
}

export async function deleteStore(id: string) {
  await http.delete(`/admin/stores/${id}`)
}

export async function replaceSchedules(storeId: string, schedules: Schedule[]) {
  await http.put(`/admin/stores/${storeId}/schedules`, { schedules })
}
