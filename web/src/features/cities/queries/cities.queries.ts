import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getAdminCities } from '../actions/cities.actions'

export const adminCitiesQuery = queryOptions({
  queryKey: queryKeys.adminCities(),
  queryFn: ({ signal }) => getAdminCities(signal),
})
