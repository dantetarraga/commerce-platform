import { useMutation, useQueryClient } from '@tanstack/react-query'
import { http } from '@/app/api'
import { partnerQuery, type PartnerAccount } from '@/app/api/admin-lookups'
import { partnerPayload, type PartnerForm, type PartnerRole } from '../schemas/partners.schemas'

export function useSavePartner() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: async (values: PartnerForm) =>
      (
        await http.post<{ created: boolean; user: PartnerAccount }>(
          values.role === 'MERCHANT' ? '/admin/merchants' : '/admin/couriers',
          partnerPayload(values),
        )
      ).data,
    onSuccess: async ({ user }) => {
      await client.cancelQueries({ queryKey: ['admin', 'partners'] })
      client.setQueryData(partnerQuery(user.phone).queryKey, user)
      await Promise.all([
        client.invalidateQueries({ queryKey: ['admin', 'stores'] }),
        client.invalidateQueries({ queryKey: ['admin', 'partners'] }),
      ])
    },
  })
}

export function useSuspendPartner() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, roles }: { id: string; roles: PartnerRole[] }) =>
      (await http.post<PartnerAccount>(`/admin/users/${id}/suspend-partner`, { roles })).data,
    onSuccess: async (user) => {
      await client.cancelQueries({ queryKey: partnerQuery(user.phone).queryKey })
      client.setQueryData(partnerQuery(user.phone).queryKey, user)
      await Promise.all([
        client.invalidateQueries({ queryKey: ['admin', 'stores'] }),
        client.invalidateQueries({ queryKey: partnerQuery(user.phone).queryKey }),
      ])
    },
  })
}
