import { OrderStatus, Role } from '../../../generated/prisma/enums';
import { median } from '../analytics/analytics-report';

/** Días que mira el desempeño de un socio. */
export const PERFORMANCE_DAYS = 30;

export interface MerchantOrder {
  status: OrderStatus;
  createdAt: Date;
  acceptedAt: Date | null;
  cancelledBy: Role | null;
}

/** Cómo atiende un negocio: cuántos acepta, en cuánto tiempo y cuántos se le caen. */
export function merchantPerformance(orders: readonly MerchantOrder[]) {
  const accepted = orders.filter((o) => o.acceptedAt !== null);
  const cancelled = orders.filter((o) => o.status === OrderStatus.CANCELLED);
  return {
    received: orders.length,
    accepted: accepted.length,
    /** 0–100, o `null` sin pedidos. */
    acceptRate: orders.length ? Math.round((accepted.length / orders.length) * 100) : null,
    responseMinutes: median(accepted.map((o) => (o.acceptedAt!.getTime() - o.createdAt.getTime()) / 60_000)),
    rejected: cancelled.filter((o) => o.cancelledBy === Role.MERCHANT).length,
    /** Cancelados por Apamuy a los 8 min sin respuesta. */
    unanswered: cancelled.filter((o) => o.cancelledBy === null && o.acceptedAt === null).length,
  };
}

export interface CourierOrder {
  status: OrderStatus;
  readyAt: Date | null;
  deliveredAt: Date | null;
  collectedAmount: number | null;
}

/** Entregas del repartidor, su tiempo típico desde que el pedido está listo y lo que cobró. */
export function courierPerformance(orders: readonly CourierOrder[]) {
  const delivered = orders.filter((o) => o.status === OrderStatus.DELIVERED);
  return {
    deliveries: delivered.length,
    deliveryMinutes: median(
      delivered
        .filter((o) => o.readyAt && o.deliveredAt)
        .map((o) => (o.deliveredAt!.getTime() - o.readyAt!.getTime()) / 60_000),
    ),
    /** Céntimos cobrados al cliente. */
    collected: delivered.reduce((sum, o) => sum + (o.collectedAmount ?? 0), 0),
  };
}
