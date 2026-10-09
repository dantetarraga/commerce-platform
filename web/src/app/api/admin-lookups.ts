import { queryOptions } from '@tanstack/react-query'
import { http } from './http'

// Contratos de consulta compartidos por Socios y Catálogo, contrastados con admin/*.
export interface CityOption {
  id: string
  name: string
  currency: string
  centerLat: number
  centerLng: number
}

export interface StoreSummary {
  id: string
  cityId: string
  ownerId: string
  name: string
  isActive: boolean
  isAcceptingOrders: boolean
  productCount: number
}

export interface PartnerAccount {
  id: string
  phone: string
  firstName: string
  lastName: string
  isActive: boolean
  roles: string[]
  stores: { id: string; name: string; isAcceptingOrders: boolean }[]
  courier: {
    cityId: string
    vehicleType: 'MOTO' | 'BICI' | 'AUTO'
    vehicleLabel: string
    plate: string | null
    status: string
  } | null
}

export const citiesQuery = queryOptions({
  queryKey: ['cities'],
  queryFn: async ({ signal }) => (await http.get<CityOption[]>('/cities', { signal })).data,
})

export const adminStoresQuery = queryOptions({
  queryKey: ['admin', 'stores'],
  queryFn: async ({ signal }) => (await http.get<StoreSummary[]>('/admin/stores', { signal })).data,
})

export function partnerQuery(phone: string) {
  return queryOptions({
    queryKey: ['admin', 'partners', phone],
    queryFn: async ({ signal }) =>
      (await http.get<PartnerAccount>('/admin/users', { params: { phone }, signal })).data,
    enabled: /^9\d{8}$/.test(phone),
    retry: false,
  })
}
