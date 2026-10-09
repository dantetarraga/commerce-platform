import { Prisma } from '../../../generated/prisma/client';

export const ADMIN_ACTIONS = [
  'PARTNER_CREATED',
  'PARTNER_SUSPENDED',
  'PARTNER_RESTORED',
  'BLOCKED',
  'UNBLOCKED',
  'SESSIONS_REVOKED',
  'ADMIN_GRANTED',
  'ADMIN_REVOKED',
] as const;
export type AdminActionType = (typeof ADMIN_ACTIONS)[number];

/** Anota en el historial de la cuenta quién del equipo hizo el cambio. */
export function recordAdminAction(
  db: Prisma.TransactionClient,
  adminId: string | undefined,
  userId: string,
  action: AdminActionType,
  details?: Prisma.InputJsonObject,
) {
  return db.adminAction.create({ data: { adminId: adminId ?? null, userId, action, details } });
}
