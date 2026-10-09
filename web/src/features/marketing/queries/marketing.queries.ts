import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getCoupons, getPromotions } from '../actions/marketing.actions'

export const couponsQuery = queryOptions({
  queryKey: queryKeys.coupons(),
  queryFn: ({ signal }) => getCoupons(signal),
})

/** `cityId` vacío: todas las ciudades. */
export const promotionsQuery = (cityId: string) =>
  queryOptions({
    queryKey: queryKeys.promotions.byCity(cityId),
    queryFn: ({ signal }) => getPromotions(cityId || undefined, signal),
  })
