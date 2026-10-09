import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { createCity, updateCity, type CityPayload } from '../actions/cities.actions'

// La lista pública de ciudades alimenta los selectores de catálogo, socios y marketing.
const refreshCities = (client: QueryClient) =>
  Promise.all([
    client.invalidateQueries({ queryKey: queryKeys.adminCities() }),
    client.invalidateQueries({ queryKey: queryKeys.cities() }),
  ])

export const saveCityMutation = (cityId?: string) =>
  mutationOptions({
    mutationFn: (payload: CityPayload) =>
      cityId ? updateCity(cityId, payload) : createCity(payload),
    onSuccess: (_data, _payload, _result, { client }) => refreshCities(client),
  })

export const toggleCityMutation = (cityId: string, isActive: boolean) =>
  mutationOptions({
    mutationFn: async () => {
      await updateCity(cityId, { isActive: !isActive })
    },
    onSuccess: (_data, _vars, _result, { client }) => refreshCities(client),
  })
