import { PaymentMethodType } from '../../../generated/prisma/enums';
import { CollectedTotals, sumCollected } from '../../couriers/courier-summary';

/** Lo que la caja necesita de cada pedido entregado. */
export interface CashOrder {
  storeId: string;
  storeName: string;
  courier: { id: string; name: string; phone: string } | null;
  subtotal: number;
  deliveryFee: number;
  tip: number;
  /** Lo que el cliente debía pagar al recibir. */
  total: number;
  collectedMethod: PaymentMethodType | null;
  collectedAmount: number | null;
}

export interface CourierCash {
  courierId: string;
  name: string;
  phone: string;
  delivered: number;
  /** Lo que debía cobrar (suma de totales). */
  expected: number;
  collected: CollectedTotals;
  /** Cobrado − esperado: negativo si cobró de menos o no registró un cobro. */
  difference: number;
}

export interface StoreCash {
  storeId: string;
  name: string;
  delivered: number;
  /** Lo vendido por el negocio: subtotales, sin envío ni propina. */
  sales: number;
  collected: CollectedTotals;
}

export interface CashReport {
  delivered: number;
  sales: number;
  deliveryFees: number;
  tips: number;
  expected: number;
  collected: CollectedTotals;
  difference: number;
  couriers: CourierCash[];
  stores: StoreCash[];
}

const sum = (orders: readonly CashOrder[], pick: (o: CashOrder) => number) =>
  orders.reduce((total, order) => total + pick(order), 0);

function groupBy<K>(orders: readonly CashOrder[], key: (o: CashOrder) => K | null): Map<K, CashOrder[]> {
  const groups = new Map<K, CashOrder[]>();
  for (const order of orders) {
    const k = key(order);
    if (k === null) continue;
    groups.set(k, [...(groups.get(k) ?? []), order]);
  }
  return groups;
}

/**
 * Rendición de los pedidos entregados: por repartidor (lo que cobró contra lo que debía
 * cobrar) y por negocio (lo que vendió). Primero quien más cobró o vendió.
 */
export function cashReport(orders: readonly CashOrder[]): CashReport {
  const collected = sumCollected(orders);
  const expected = sum(orders, (o) => o.total);

  const couriers = [...groupBy(orders, (o) => o.courier?.id ?? null).values()].map((group) => {
    const courier = group[0].courier!;
    const totals = sumCollected(group);
    const owed = sum(group, (o) => o.total);
    return {
      courierId: courier.id,
      name: courier.name,
      phone: courier.phone,
      delivered: group.length,
      expected: owed,
      collected: totals,
      difference: totals.total - owed,
    };
  });

  const stores = [...groupBy(orders, (o) => o.storeId).values()].map((group) => ({
    storeId: group[0].storeId,
    name: group[0].storeName,
    delivered: group.length,
    sales: sum(group, (o) => o.subtotal),
    collected: sumCollected(group),
  }));

  return {
    delivered: orders.length,
    sales: sum(orders, (o) => o.subtotal),
    deliveryFees: sum(orders, (o) => o.deliveryFee),
    tips: sum(orders, (o) => o.tip),
    expected,
    collected,
    difference: collected.total - expected,
    couriers: couriers.sort((a, b) => b.collected.total - a.collected.total || a.name.localeCompare(b.name, 'es')),
    stores: stores.sort((a, b) => b.sales - a.sales || a.name.localeCompare(b.name, 'es')),
  };
}
