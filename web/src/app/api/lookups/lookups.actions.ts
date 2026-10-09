import { ApiError } from '../api-error'
import { http } from '../http'
import type { CityOption, OwnStore, PartnerAccount, StoreSummary } from './lookups.types'

export async function getCities(signal?: AbortSignal) {
  return (await http.get<CityOption[]>('/cities', { signal })).data
}

export async function getAdminStores(signal?: AbortSignal) {
  return (await http.get<StoreSummary[]>('/admin/stores', { signal })).data
}

/** `null` si no hay cuenta con ese celular: es un resultado, no un error. */
export async function findPartnerByPhone(phone: string, signal?: AbortSignal) {
  try {
    return (await http.get<PartnerAccount>('/admin/partners/lookup', { params: { phone }, signal }))
      .data
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null
    throw error
  }
}

export async function getOwnStores(signal?: AbortSignal) {
  return (await http.get<OwnStore[]>('/merchant/stores', { signal })).data
}

/** Pausa o reanuda la recepción de pedidos (el interruptor de la app Socios). */
export async function setAcceptingOrders(storeId: string, isAcceptingOrders: boolean) {
  await http.patch(`/merchant/stores/${storeId}`, { isAcceptingOrders })
}
