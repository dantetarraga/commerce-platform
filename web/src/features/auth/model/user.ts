export type Role = 'CUSTOMER' | 'MERCHANT' | 'COURIER' | 'ADMIN'

export interface SessionUser {
  id: string
  phone: string
  firstName: string
  lastName: string
  email: string | null
  avatarUrl: string | null
  roles: Role[]
}

export type PanelRole = Extract<Role, 'ADMIN' | 'MERCHANT'>

export function panelHomeFor(user: Pick<SessionUser, 'roles'>): '/admin' | '/socio' | null {
  if (user.roles.includes('ADMIN')) return '/admin'
  if (user.roles.includes('MERCHANT')) return '/socio'
  return null
}

export function hasAnyRole(user: Pick<SessionUser, 'roles'>, roles: readonly Role[]): boolean {
  return user.roles.some((role) => roles.includes(role))
}

export function displayName(user: Pick<SessionUser, 'firstName' | 'lastName'>): string {
  return `${user.firstName} ${user.lastName}`.trim()
}

export function initials(user: Pick<SessionUser, 'firstName' | 'lastName'>): string {
  return `${user.firstName.charAt(0)}${user.lastName.charAt(0)}`.toUpperCase()
}
