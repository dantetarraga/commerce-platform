import { ApiError } from '../api-error'
import { http } from '../http'
import type { CityOption, PartnerAccount, StoreSummary } from './lookups.types'

export async function getCities(signal?: AbortSignal) {
  return (await http.get<CityOption[]>('/cities', { signal })).data
}

export async function getAdminStores(signal?: AbortSignal) {
  return (await http.get<StoreSummary[]>('/admin/stores', { signal })).data
}

/** `null` si no hay cuenta con ese celular: es un resultado, no un error. */
export async function findPartnerByPhone(phone: string, signal?: AbortSignal) {
  try {
    return (await http.get<PartnerAccount>('/admin/users', { params: { phone }, signal })).data
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null
    throw error
  }
}
