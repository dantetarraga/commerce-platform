import { OrderStatus } from '../../generated/prisma/enums';
import { summarizeMerchantDay } from './merchant-summary';

describe('summarizeMerchantDay', () => {
  it('sin pedidos, todo en cero', () => {
    expect(summarizeMerchantDay([])).toEqual({ deliveredCount: 0, cancelledCount: 0, activeCount: 0, sales: 0 });
  });

  it('las ventas suman solo el subtotal de los entregados', () => {
    const summary = summarizeMerchantDay([
      { status: OrderStatus.DELIVERED, subtotal: 3000 },
      { status: OrderStatus.DELIVERED, subtotal: 1550 },
      { status: OrderStatus.CANCELLED, subtotal: 9900 },
      { status: OrderStatus.RECEIVED, subtotal: 2000 },
      { status: OrderStatus.ON_THE_WAY, subtotal: 2000 },
    ]);
    expect(summary).toEqual({ deliveredCount: 2, cancelledCount: 1, activeCount: 2, sales: 4550 });
  });
});
