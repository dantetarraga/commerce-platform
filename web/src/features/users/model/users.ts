import type { Money } from '@/lib/money'

export type UserRole = 'CUSTOMER' | 'MERCHANT' | 'COURIER' | 'ADMIN'
export type PartnerRole = 'MERCHANT' | 'COURIER'

/** Fila de `GET admin/users`. */
export interface UserRow {
  id: string
  phone: string
  firstName: string
  lastName: string
  isActive: boolean
  roles: UserRole[]
  createdAt: string
  orders: number
  lastOrderAt: string | null
  stores: { id: string; name: string }[]
  courier: { vehicleLabel: string; status: string } | null
}

export interface UsersPage {
  items: UserRow[]
  page: number
  pageSize: number
  total: number
}

export type AdminActionType =
  | 'PARTNER_CREATED'
  | 'PARTNER_SUSPENDED'
  | 'PARTNER_RESTORED'
  | 'BLOCKED'
  | 'UNBLOCKED'
  | 'SESSIONS_REVOKED'
  | 'ADMIN_GRANTED'
  | 'ADMIN_REVOKED'

/** `GET admin/users/:id`. */
export interface UserDetail extends Omit<UserRow, 'stores' | 'courier'> {
  email: string | null
  addresses: number
  activeSessions: number
  stores: { id: string; name: string; isAcceptingOrders: boolean }[]
  courier: {
    id: string
    vehicleType: string
    vehicleLabel: string
    plate: string | null
    status: string
  } | null
  devices: { platform: string; app: string; updatedAt: string }[]
  stats: {
    orders: number
    delivered: number
    cancelled: number
    spent: Money
    avgTicket: Money
    firstOrderAt: string | null
  }
  recentOrders: {
    id: string
    code: string
    storeName: string
    status: string
    total: Money
    createdAt: string
  }[]
  performance: {
    days: number
    merchant: {
      received: number
      accepted: number
      acceptRate: number | null
      responseMinutes: number | null
      rejected: number
      unanswered: number
    } | null
    courier: { deliveries: number; deliveryMinutes: number | null; collected: Money } | null
  }
  history: {
    id: string
    action: AdminActionType
    details: Record<string, unknown> | null
    createdAt: string
    by: string | null
  }[]
}

export const ROLE_LABEL: Record<UserRole, string> = {
  CUSTOMER: 'Cliente',
  MERCHANT: 'Negocio',
  COURIER: 'Repartidor',
  ADMIN: 'Admin',
}

export const ACTION_LABEL: Record<AdminActionType, string> = {
  PARTNER_CREATED: 'Alta como socio',
  PARTNER_SUSPENDED: 'Socio suspendido',
  PARTNER_RESTORED: 'Socio reactivado',
  BLOCKED: 'Cuenta bloqueada',
  UNBLOCKED: 'Cuenta desbloqueada',
  SESSIONS_REVOKED: 'Sesiones cerradas',
  ADMIN_GRANTED: 'Acceso de admin',
  ADMIN_REVOKED: 'Sin acceso de admin',
}

export const ORDER_STATUS_LABEL: Record<string, string> = {
  RECEIVED: 'Nuevo',
  CONFIRMED: 'Aceptado',
  PREPARING: 'Preparando',
  READY: 'Listo',
  COURIER_ASSIGNED: 'Con repartidor',
  ON_THE_WAY: 'En camino',
  DELIVERED: 'Entregado',
  CANCELLED: 'Cancelado',
}

export const fullName = (user: { firstName: string; lastName: string }) =>
  `${user.firstName} ${user.lastName}`.trim()

/** Roles de socio que una suspensión le quitó pero cuyo registro sigue (vehículo o negocios). */
export function suspendedPartnerRoles(user: UserDetail): PartnerRole[] {
  const roles: PartnerRole[] = []
  if (user.stores.length > 0 && !user.roles.includes('MERCHANT')) roles.push('MERCHANT')
  if (user.courier && !user.roles.includes('COURIER')) roles.push('COURIER')
  return roles
}
