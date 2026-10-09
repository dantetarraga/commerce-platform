import { http } from '@/app/api'
import type { AdminCity } from '../model/city'
import type { cityPayload } from '../schemas/city.schemas'

export type CityPayload = ReturnType<typeof cityPayload>

export async function getAdminCities(signal?: AbortSignal) {
  return (await http.get<AdminCity[]>('/admin/cities', { signal })).data
}

export async function createCity(payload: CityPayload) {
  return (await http.post<AdminCity>('/admin/cities', payload)).data
}

export async function updateCity(id: string, payload: Partial<CityPayload>) {
  return (await http.patch<AdminCity>(`/admin/cities/${id}`, payload)).data
}
