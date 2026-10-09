import { http } from '@/app/api'
import type { PartnerRole, UserDetail, UserRole, UsersPage } from '../model/users'

export interface UsersFilters {
  q: string
  /** Vacío: todos. */
  role: UserRole | ''
  status: 'active' | 'blocked' | ''
}

export async function listUsers(filters: UsersFilters, page: number, signal?: AbortSignal) {
  const params = {
    page,
    pageSize: 25,
    ...(filters.q && { q: filters.q }),
    ...(filters.role && { role: filters.role }),
    ...(filters.status && { status: filters.status }),
  }
  return (await http.get<UsersPage>('/admin/users', { params, signal })).data
}

export async function getUser(id: string, signal?: AbortSignal) {
  return (await http.get<UserDetail>(`/admin/users/${id}`, { signal })).data
}

export async function blockUser(id: string, reason: string) {
  return (await http.post<UserDetail>(`/admin/users/${id}/block`, reason ? { reason } : {})).data
}

export async function unblockUser(id: string) {
  return (await http.post<UserDetail>(`/admin/users/${id}/unblock`)).data
}

export async function restorePartner(id: string, roles: PartnerRole[]) {
  return (await http.post<UserDetail>(`/admin/users/${id}/restore-partner`, { roles })).data
}

export async function revokeSessions(id: string) {
  return (await http.post<UserDetail>(`/admin/users/${id}/revoke-sessions`)).data
}

export async function setAdmin(id: string, isAdmin: boolean) {
  return (await http.put<UserDetail>(`/admin/users/${id}/admin`, { isAdmin })).data
}
