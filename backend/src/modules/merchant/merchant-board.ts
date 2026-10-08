import { OrderStatus } from '../../generated/prisma/enums';

/** Las tres columnas del tablero del negocio, en orden. */
export const BOARD_COLUMNS = [
  { key: 'fresh', statuses: [OrderStatus.RECEIVED] },
  { key: 'cooking', statuses: [OrderStatus.CONFIRMED, OrderStatus.PREPARING] },
  { key: 'ready', statuses: [OrderStatus.READY, OrderStatus.COURIER_ASSIGNED, OrderStatus.ON_THE_WAY] },
] as const;

/**
 * Reparte los pedidos en curso en las columnas, conservando su orden. Todas
 * las columnas vienen, aunque estén vacías; los finales no entran.
 */
export function groupBoard<T extends { status: OrderStatus }>(orders: readonly T[]) {
  return BOARD_COLUMNS.map((column) => {
    const items = orders.filter((o) => (column.statuses as readonly OrderStatus[]).includes(o.status));
    return { key: column.key, count: items.length, items };
  });
}

/** Tope de pedidos en curso que trae el tablero (una cocina de barrio no llega). */
export const BOARD_LIMIT = 200;
