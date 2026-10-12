import { commissionOf } from './commission';

/** Lo que la liquidación necesita de cada pedido entregado. */
export interface SettlementOrder {
  id: string;
  code: string;
  deliveredAt: Date;
  /** Céntimos: lo vendido por el negocio, sin envío ni propina. */
  subtotal: number;
  /** Comisión guardada al crear el pedido; null en pedidos anteriores a la comisión. */
  commissionRateBps: number | null;
  collectedById: string | null;
  collectedAmount: number | null;
}

export interface SettledOrder extends SettlementOrder {
  rateBps: number;
  commission: number;
  /** Lo que cobró el propio negocio (su dueño marcó la entrega); 0 si cobró un repartidor. */
  collectedByStore: number;
}

export interface WeeklySettlement {
  delivered: number;
  sales: number;
  commission: number;
  collectedByStore: number;
  /** vendido − comisión − cobrado por el negocio. > 0: Apamuy le debe al negocio; < 0: el negocio a Apamuy. */
  balance: number;
  orders: SettledOrder[];
}

export type OwedTo = 'STORE' | 'APAMUY' | null;

export const owedTo = (balance: number): OwedTo => (balance > 0 ? 'STORE' : balance < 0 ? 'APAMUY' : null);

/**
 * Liquidación de un negocio en una semana. Hoy cobra el repartidor y lo rinde a la
 * caja de Apamuy, así que el saldo suele quedar a favor del negocio. [fallbackRateBps]
 * cubre los pedidos sin comisión guardada.
 */
export function settleWeek(
  orders: readonly SettlementOrder[],
  { ownerId, fallbackRateBps }: { ownerId: string; fallbackRateBps: number },
): WeeklySettlement {
  const settled = orders
    .map((order) => {
      const rateBps = order.commissionRateBps ?? fallbackRateBps;
      return {
        ...order,
        rateBps,
        commission: commissionOf(order.subtotal, rateBps),
        collectedByStore: order.collectedById === ownerId ? (order.collectedAmount ?? 0) : 0,
      };
    })
    .sort((a, b) => a.deliveredAt.getTime() - b.deliveredAt.getTime());
  const sum = (pick: (o: SettledOrder) => number) => settled.reduce((total, order) => total + pick(order), 0);
  const sales = sum((o) => o.subtotal);
  const commission = sum((o) => o.commission);
  const collectedByStore = sum((o) => o.collectedByStore);
  return {
    delivered: settled.length,
    sales,
    commission,
    collectedByStore,
    balance: sales - commission - collectedByStore,
    orders: settled,
  };
}

export type SettlementStatus = 'OPEN' | 'PENDING' | 'PAID' | 'EMPTY';

/**
 * OPEN mientras la semana no termina; luego PENDING hasta que el admin la marca pagada.
 * EMPTY: terminó sin pedidos entregados, no hay nada que liquidar.
 */
export function settlementStatus(weekEnd: Date, now: Date, paid: boolean, delivered: number): SettlementStatus {
  if (paid) return 'PAID';
  if (now < weekEnd) return 'OPEN';
  return delivered > 0 ? 'PENDING' : 'EMPTY';
}
