import { OrderStatus, Role } from '../../../generated/prisma/enums';
import { courierPerformance, merchantPerformance } from './partner-performance';

const t = (minutes: number) => new Date(Date.UTC(2026, 9, 9, 12, minutes));

describe('merchantPerformance', () => {
  it('cuenta aceptados, rechazados y los que dejó sin responder', () => {
    const result = merchantPerformance([
      { status: OrderStatus.DELIVERED, createdAt: t(0), acceptedAt: t(2), cancelledBy: null },
      { status: OrderStatus.DELIVERED, createdAt: t(0), acceptedAt: t(4), cancelledBy: null },
      { status: OrderStatus.CANCELLED, createdAt: t(0), acceptedAt: null, cancelledBy: Role.MERCHANT },
      { status: OrderStatus.CANCELLED, createdAt: t(0), acceptedAt: null, cancelledBy: null },
    ]);
    expect(result).toEqual({
      received: 4,
      accepted: 2,
      acceptRate: 50,
      responseMinutes: 3,
      rejected: 1,
      unanswered: 1,
    });
  });

  it('sin pedidos no inventa porcentajes', () => {
    expect(merchantPerformance([])).toMatchObject({ received: 0, acceptRate: null, responseMinutes: null });
  });
});

describe('courierPerformance', () => {
  it('suma entregas y lo cobrado, y mide desde que el pedido está listo', () => {
    const result = courierPerformance([
      { status: OrderStatus.DELIVERED, readyAt: t(0), deliveredAt: t(15), collectedAmount: 3500 },
      { status: OrderStatus.DELIVERED, readyAt: t(0), deliveredAt: t(25), collectedAmount: 2000 },
      { status: OrderStatus.ON_THE_WAY, readyAt: t(0), deliveredAt: null, collectedAmount: null },
    ]);
    expect(result).toEqual({ deliveries: 2, deliveryMinutes: 20, collected: 5500 });
  });
});
