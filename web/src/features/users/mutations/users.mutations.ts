import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  blockUser,
  restorePartner,
  revokeSessions,
  setAdmin,
  unblockUser,
} from '../actions/users.actions'
import type { PartnerRole } from '../model/users'

/** Cambia la cuenta y refresca su ficha, la lista y Socios (que busca la misma cuenta). */
function userMutation<T = void>(action: (input: T) => Promise<unknown>) {
  return mutationOptions<void, Error, T>({
    mutationFn: async (input) => {
      await action(input)
    },
    onSuccess: async (_data, _input, _result, { client }) => {
      await client.invalidateQueries({ queryKey: queryKeys.users.all() })
      await client.invalidateQueries({ queryKey: queryKeys.partners.all() })
    },
  })
}

export const blockUserMutation = (id: string) =>
  userMutation((reason: string) => blockUser(id, reason))

export const unblockUserMutation = (id: string) => userMutation(() => unblockUser(id))

export const restorePartnerMutation = (id: string, roles: PartnerRole[]) =>
  userMutation(() => restorePartner(id, roles))

export const revokeSessionsMutation = (id: string) => userMutation(() => revokeSessions(id))

export const setAdminMutation = (id: string, isAdmin: boolean) =>
  userMutation(() => setAdmin(id, isAdmin))
