import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  createStore,
  deleteStore,
  replaceSchedules,
  setStorePublished,
  updateStore,
  updateStoreProfile,
  type StoreProfile,
  type StorePayload,
} from '../actions/stores.actions'
import { setAcceptingOrders } from '@/app/api/lookups'
import type { CatalogScope } from '../model/catalog-scope'
import type { Schedule } from '../model/catalog'

// La ficha de un socio lista sus negocios: cambia con cualquier alta, baja o edición.
const refreshStores = (client: QueryClient) =>
  Promise.all([
    client.invalidateQueries({ queryKey: queryKeys.stores.all() }),
    client.invalidateQueries({ queryKey: queryKeys.partners.all() }),
  ])

export const saveStoreMutation = (storeId?: string) =>
  mutationOptions({
    mutationFn: (payload: StorePayload) => {
      if (!storeId) return createStore(payload)
      // La ciudad no se cambia después de crear el negocio.
      const { cityId: _cityId, ...update } = payload
      return updateStore(storeId, update)
    },
    onSuccess: (_data, _payload, _result, { client }) => refreshStores(client),
  })

export const toggleStorePublishedMutation = (storeId: string, isActive: boolean) =>
  mutationOptions({
    mutationFn: async () => {
      await setStorePublished(storeId, !isActive)
    },
    onSuccess: (_data, _vars, _result, { client }) => refreshStores(client),
  })

export const deleteStoreMutation = (storeId: string) =>
  mutationOptions({
    mutationFn: () => deleteStore(storeId),
    onSuccess: async (_data, _vars, _result, { client }) => {
      client.removeQueries({ queryKey: queryKeys.stores.detail(storeId) })
      await refreshStores(client)
    },
  })

export const saveStoreProfileMutation = (storeId: string) =>
  mutationOptions({
    mutationFn: (profile: StoreProfile) => updateStoreProfile(storeId, profile),
    onSuccess: (_data, _profile, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })

/** El interruptor de la app Socios: el negocio deja de recibir pedidos sin despublicarse. */
export const toggleAcceptingOrdersMutation = (storeId: string, isAcceptingOrders: boolean) =>
  mutationOptions({
    mutationFn: () => setAcceptingOrders(storeId, !isAcceptingOrders),
    onSuccess: (_data, _vars, _result, { client }) =>
      Promise.all([
        client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
        client.invalidateQueries({ queryKey: queryKeys.ownStores() }),
      ]),
  })

export const saveSchedulesMutation = (storeId: string, scope: CatalogScope) =>
  mutationOptions({
    mutationFn: (schedules: Schedule[]) => replaceSchedules(storeId, schedules, scope),
    onSuccess: (_data, _vars, _result, { client }) =>
      client.invalidateQueries({ queryKey: queryKeys.stores.detail(storeId) }),
  })
