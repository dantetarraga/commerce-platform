import { http } from '@/app/api'
import type { Schedule, StoreDetail } from '../model/catalog'
import { catalogBase, type CatalogScope } from '../model/catalog-scope'
import type { storePayload } from '../schemas/catalog.schemas'

export type StorePayload = ReturnType<typeof storePayload>
export type StoreUpdate = Omit<StorePayload, 'cityId'>

export async function getStore(id: string, scope: CatalogScope, signal?: AbortSignal) {
  return (await http.get<StoreDetail>(`${catalogBase(scope)}/stores/${id}`, { signal })).data
}

/** Los negocios nuevos nacen como borrador. */
export async function createStore(payload: StorePayload) {
  return (await http.post<StoreDetail>('/admin/stores', { ...payload, isActive: false })).data
}

export async function updateStore(id: string, update: StoreUpdate) {
  return (await http.patch<StoreDetail>(`/admin/stores/${id}`, update)).data
}

/** Lo que el dueño cambia desde el Portal Socios. */
export interface StoreProfile {
  description: string
  phone: string | null
  logoUrl: string | null
  coverUrl: string | null
  avgPrepMinutes: number
  minOrderAmount: { amount: number; currency: string }
}

export async function updateStoreProfile(id: string, profile: StoreProfile) {
  return (await http.patch<StoreDetail>(`/merchant/catalog/stores/${id}`, profile)).data
}

export async function setStorePublished(id: string, isActive: boolean) {
  return (await http.patch<StoreDetail>(`/admin/stores/${id}`, { isActive })).data
}

export async function deleteStore(id: string) {
  await http.delete(`/admin/stores/${id}`)
}

export async function replaceSchedules(
  storeId: string,
  schedules: Schedule[],
  scope: CatalogScope,
) {
  await http.put(`${catalogBase(scope)}/stores/${storeId}/schedules`, { schedules })
}
