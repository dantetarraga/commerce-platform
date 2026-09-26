import { OrderStatus } from '../../generated/prisma/enums';

export interface MerchantDaySummary {
  deliveredCount: number;
  cancelledCount: number;
  activeCount: number;
  /** Céntimos: suma del `subtotal` de los entregados (el envío es del repartidor). */
  sales: number;
}

/** Resumen del día del negocio a partir de los pedidos creados ese día. */
export function summarizeMerchantDay(orders: readonly { status: OrderStatus; subtotal: number }[]): MerchantDaySummary {
  const summary: MerchantDaySummary = { deliveredCount: 0, cancelledCount: 0, activeCount: 0, sales: 0 };
  for (const order of orders) {
    if (order.status === OrderStatus.DELIVERED) {
      summary.deliveredCount++;
      summary.sales += order.subtotal;
    } else if (order.status === OrderStatus.CANCELLED) {
      summary.cancelledCount++;
    } else {
      summary.activeCount++;
    }
  }
  return summary;
}
