import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '../query-keys'
import { findPartnerByPhone, getAdminStores, getCities, getOwnStores } from './lookups.actions'

export const isNationalPhone = (phone: string) => /^9\d{8}$/.test(phone)

export const citiesQuery = queryOptions({
  queryKey: queryKeys.cities(),
  queryFn: ({ signal }) => getCities(signal),
  // Las ciudades casi no cambian.
  staleTime: 5 * 60_000,
})

export const adminStoresQuery = queryOptions({
  queryKey: queryKeys.stores.list(),
  queryFn: ({ signal }) => getAdminStores(signal),
})

export const partnerQuery = (phone: string) =>
  queryOptions({
    queryKey: queryKeys.partners.byPhone(phone),
    queryFn: ({ signal }) => findPartnerByPhone(phone, signal),
  })

export const ownStoresQuery = queryOptions({
  queryKey: queryKeys.ownStores(),
  queryFn: ({ signal }) => getOwnStores(signal),
})
