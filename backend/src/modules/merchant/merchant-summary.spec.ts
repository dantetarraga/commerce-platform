import { OrderStatus, PaymentMethodType } from '../../generated/prisma/enums';
import { SummaryOrder, summarizeMerchantDay } from './merchant-summary';

// Horas "locales" de prueba: la hora UTC del instante.
const hourOf = (at: Date) => at.getUTCHours();
const at = (hour: number, minute = 0) => new Date(Date.UTC(2026, 9, 8, hour, minute));

function order(overrides: Partial<SummaryOrder> = {}): SummaryOrder {
  return {
    status: OrderStatus.DELIVERED,
    subtotal: 2000,
    createdAt: at(12),
    acceptedAt: null,
    readyAt: null,
    paymentMethod: PaymentMethodType.CASH,
    collectedMethod: null,
    items: [],
    ...overrides,
  };
}

describe('summarizeMerchantDay', () => {
  it('sin pedidos, todo en cero y sin gráficas', () => {
    expect(summarizeMerchantDay([], hourOf)).toEqual({
      deliveredCount: 0,
      cancelledCount: 0,
      activeCount: 0,
      sales: 0,
      averageTicket: null,
      averagePrepMinutes: null,
      salesByHour: [],
      peakHour: null,
      payments: [
        { method: PaymentMethodType.CASH, sales: 0, orders: 0, share: 0 },
        { method: PaymentMethodType.YAPE, sales: 0, orders: 0, share: 0 },
        { method: PaymentMethodType.PLIN, sales: 0, orders: 0, share: 0 },
      ],
      topProducts: [],
    });
  });

  it('las ventas y el ticket promedio cuentan solo los entregados', () => {
    const summary = summarizeMerchantDay(
      [
        order({ subtotal: 3000 }),
        order({ subtotal: 1550 }),
        order({ status: OrderStatus.CANCELLED, subtotal: 9900 }),
        order({ status: OrderStatus.RECEIVED }),
        order({ status: OrderStatus.ON_THE_WAY }),
      ],
      hourOf,
    );
    expect(summary).toMatchObject({
      deliveredCount: 2,
      cancelledCount: 1,
      activeCount: 2,
      sales: 4550,
      averageTicket: 2275,
    });
  });

  it('ventas por hora: horas seguidas, las vacías en cero, y la hora pico', () => {
    const summary = summarizeMerchantDay(
      [
        order({ createdAt: at(11, 10), subtotal: 1000 }),
        order({ createdAt: at(13, 5), subtotal: 2500 }),
        order({ createdAt: at(13, 50), subtotal: 500 }),
        order({ createdAt: at(9), status: OrderStatus.CANCELLED }),
      ],
      hourOf,
    );
    expect(summary.salesByHour).toEqual([
      { hour: 11, sales: 1000, orders: 1 },
      { hour: 12, sales: 0, orders: 0 },
      { hour: 13, sales: 3000, orders: 2 },
    ]);
    expect(summary.peakHour).toBe(13);
  });

  it('tiempo de preparación: de aceptado a listo, también en los que siguen activos', () => {
    const summary = summarizeMerchantDay(
      [
        order({ acceptedAt: at(12, 0), readyAt: at(12, 10) }),
        order({ status: OrderStatus.COURIER_ASSIGNED, acceptedAt: at(12, 0), readyAt: at(12, 21) }),
        order({ status: OrderStatus.PREPARING, acceptedAt: at(12, 0) }),
      ],
      hourOf,
    );
    expect(summary.averagePrepMinutes).toBe(16);
  });

  it('pagos: usa lo que registró el repartidor y los porcentajes suman 100', () => {
    const summary = summarizeMerchantDay(
      [
        order({ subtotal: 1000, paymentMethod: PaymentMethodType.CASH }),
        order({ subtotal: 1000, paymentMethod: PaymentMethodType.CASH, collectedMethod: PaymentMethodType.YAPE }),
        order({ subtotal: 1000, paymentMethod: PaymentMethodType.PLIN }),
      ],
      hourOf,
    );
    expect(summary.payments).toEqual([
      { method: PaymentMethodType.CASH, sales: 1000, orders: 1, share: 34 },
      { method: PaymentMethodType.YAPE, sales: 1000, orders: 1, share: 33 },
      { method: PaymentMethodType.PLIN, sales: 1000, orders: 1, share: 33 },
    ]);
  });

  it('lo más pedido: por unidades, junta el mismo producto y corta en 5', () => {
    const item = (productId: string | null, productName: string, quantity: number) => ({
      productId,
      productName,
      quantity,
      subtotal: quantity * 1000,
    });
    const summary = summarizeMerchantDay(
      [
        order({ items: [item('p1', 'Pollo', 2), item('p2', 'Caldo', 1), item(null, 'Plato borrado', 4)] }),
        order({ items: [item('p1', 'Pollo', 3), item('p3', 'Chicha', 1), item('p4', 'Papas', 1)] }),
        order({ items: [item('p5', 'Ensalada', 1)] }),
        order({ status: OrderStatus.CANCELLED, items: [item('p2', 'Caldo', 9)] }),
      ],
      hourOf,
    );
    expect(summary.topProducts.map((p) => [p.name, p.quantity])).toEqual([
      ['Pollo', 5],
      ['Plato borrado', 4],
      ['Caldo', 1],
      ['Chicha', 1],
      ['Ensalada', 1],
    ]);
  });
});
