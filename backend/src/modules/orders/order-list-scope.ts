import { DEFAULT_TIMEZONE, zonedTime } from '../../common/time';
import { Prisma } from '../../generated/prisma/client';
import { OrderStatus } from '../../generated/prisma/enums';

/** `?scope=` de las listas de negocio y repartidor. */
export const ORDER_LIST_SCOPES = ['active', 'today'] as const;
export type OrderListScope = (typeof ORDER_LIST_SCOPES)[number];

export const FINAL_STATUSES = [OrderStatus.DELIVERED, OrderStatus.CANCELLED];

/**
 * `active`: pedidos no finales (RECEIVED … ON_THE_WAY). `today`: los creados
 * hoy en hora local. Sin scope, todos.
 */
export function listScopeWhere(scope: OrderListScope | undefined, now = new Date()): Prisma.OrderWhereInput {
  switch (scope) {
    case 'active':
      return { status: { notIn: FINAL_STATUSES } };
    case 'today': {
      const { start, end } = zonedTime.dayRange(zonedTime.localDate(now, DEFAULT_TIMEZONE), DEFAULT_TIMEZONE);
      return { createdAt: { gte: start, lt: end } };
    }
    default:
      return {};
  }
}
