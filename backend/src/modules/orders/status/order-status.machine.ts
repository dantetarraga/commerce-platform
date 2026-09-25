import { OrderStatus, Role } from '../../../generated/prisma/enums';

// Transiciones permitidas del pedido, por rol. Función pura: el servicio la
// consulta y además verifica que el pedido sea del actor (negocio o courier).
//
// RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED
//     └──────────┴───────────┴─────────┴──────────┴───────────────┴──▶ CANCELLED

const FLOW: Partial<Record<OrderStatus, { next: OrderStatus; by: Role[] }>> = {
  [OrderStatus.RECEIVED]: { next: OrderStatus.CONFIRMED, by: [Role.MERCHANT, Role.ADMIN] },
  [OrderStatus.CONFIRMED]: { next: OrderStatus.PREPARING, by: [Role.MERCHANT, Role.ADMIN] },
  [OrderStatus.PREPARING]: { next: OrderStatus.READY, by: [Role.MERCHANT, Role.ADMIN] },
  [OrderStatus.READY]: { next: OrderStatus.COURIER_ASSIGNED, by: [Role.COURIER, Role.ADMIN] },
  [OrderStatus.COURIER_ASSIGNED]: { next: OrderStatus.ON_THE_WAY, by: [Role.COURIER, Role.ADMIN] },
  [OrderStatus.ON_THE_WAY]: { next: OrderStatus.DELIVERED, by: [Role.COURIER, Role.ADMIN] },
};

/** Hasta qué estados puede cancelar cada rol. El courier no cancela. */
const CANCELLABLE_BY: Record<Role, OrderStatus[]> = {
  [Role.CUSTOMER]: [OrderStatus.RECEIVED, OrderStatus.CONFIRMED],
  [Role.MERCHANT]: [OrderStatus.RECEIVED, OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.READY],
  [Role.COURIER]: [],
  [Role.ADMIN]: [
    OrderStatus.RECEIVED,
    OrderStatus.CONFIRMED,
    OrderStatus.PREPARING,
    OrderStatus.READY,
    OrderStatus.COURIER_ASSIGNED,
    OrderStatus.ON_THE_WAY,
  ],
};

export function isFinal(status: OrderStatus): boolean {
  return status === OrderStatus.DELIVERED || status === OrderStatus.CANCELLED;
}

export function nextStatus(status: OrderStatus): OrderStatus | undefined {
  return FLOW[status]?.next;
}

export function canTransition(from: OrderStatus, to: OrderStatus, role: Role): boolean {
  if (to === OrderStatus.CANCELLED) return CANCELLABLE_BY[role].includes(from);
  const step = FLOW[from];
  return step?.next === to && step.by.includes(role);
}
