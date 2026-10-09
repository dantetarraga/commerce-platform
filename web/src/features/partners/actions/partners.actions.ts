import { http } from '@/app/api'
import type { PartnerAccount } from '@/app/api/lookups'
import type { partnerPayload, PartnerRole } from '../schemas/partners.schemas'

export type PartnerPayload = ReturnType<typeof partnerPayload>

/** Da de alta o actualiza al socio; `created` dice si la cuenta era nueva. */
export async function savePartner(role: PartnerRole, payload: PartnerPayload) {
  const path = role === 'MERCHANT' ? '/admin/merchants' : '/admin/couriers'
  return (await http.post<{ created: boolean; user: PartnerAccount }>(path, payload)).data
}

export async function suspendPartner(id: string, roles: PartnerRole[]) {
  return (await http.post<PartnerAccount>(`/admin/users/${id}/suspend-partner`, { roles })).data
}
