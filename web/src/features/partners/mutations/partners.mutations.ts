import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import type { PartnerAccount } from '@/app/api/lookups'
import { savePartner, suspendPartner } from '../actions/partners.actions'
import { partnerPayload, type PartnerForm, type PartnerRole } from '../schemas/partners.schemas'

// La respuesta ya trae la ficha actualizada: se pone en caché sin volver a pedirla.
async function showUpdatedPartner(client: QueryClient, user: PartnerAccount) {
  const key = queryKeys.partners.byPhone(user.phone)
  await client.cancelQueries({ queryKey: key })
  client.setQueryData(key, user)
  // Asignar o suspender cambia el dueño visible de sus negocios.
  await client.invalidateQueries({ queryKey: queryKeys.stores.all() })
}

export const savePartnerMutation = () =>
  mutationOptions({
    mutationFn: (values: PartnerForm) => savePartner(values.role, partnerPayload(values)),
    onSuccess: ({ user }, _values, _result, { client }) => showUpdatedPartner(client, user),
  })

export const suspendPartnerMutation = (id: string) =>
  mutationOptions({
    mutationFn: (roles: PartnerRole[]) => suspendPartner(id, roles),
    onSuccess: (user, _roles, _result, { client }) => showUpdatedPartner(client, user),
  })
