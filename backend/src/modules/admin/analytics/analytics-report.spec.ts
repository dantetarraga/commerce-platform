import { OrderStatus, PaymentMethodType, Role } from '../../../generated/prisma/enums';
import { AnalyticsOrder, analyticsReport, median } from './analytics-report';

const at = (iso: string) => new Date(`${iso}Z`);
const plus = (date: Date, minutes: number) => new Date(date.getTime() + minutes * 60_000);

function order(overrides: Partial<AnalyticsOrder> = {}): AnalyticsOrder {
  const createdAt = overrides.createdAt ?? at('2026-10-05T18:00:00');
  return {
    status: OrderStatus.DELIVERED,
    subtotal: 3000,
    total: 3500,
    discountTotal: 0,
    createdAt,
    acceptedAt: plus(createdAt, 2),
    readyAt: plus(createdAt, 22),
    deliveredAt: plus(createdAt, 40),
    scheduledFor: null,
    cancelledBy: null,
    cancelReason: null,
    customerId: 'alex',
    storeId: 'pollos',
    storeName: 'Pollería',
    couponCode: null,
    paymentMethod: PaymentMethodType.CASH,
    courier: { id: 'luis', name: 'Luis Q.' },
    items: [{ productName: '1/4 de pollo', quantity: 2, subtotal: 3000 }],
    ...overrides,
  };
}

const report = (
  orders: AnalyticsOrder[],
  previousOrders: AnalyticsOrder[] = [],
  firstOrderAt = new Map<string, Date>(),
) =>
  analyticsReport({
    orders,
    previousOrders,
    firstOrderAt,
    start: at('2026-10-05T00:00:00'),
    previousStart: at('2026-10-03T00:00:00'),
    days: ['2026-10-05', '2026-10-06'],
    dayOf: (d) => d.toISOString().slice(0, 10),
    hourOf: (d) => d.getUTCHours(),
    weekdayOf: (d) => d.getUTCDay(),
  });

describe('analyticsReport', () => {
  it('suma pedidos, ventas y ticket promedio de los entregados', () => {
    const { kpis } = report([
      order(),
      order({ customerId: 'rosa', total: 4500, subtotal: 4000 }),
      order({ status: OrderStatus.CANCELLED, cancelledBy: Role.MERCHANT, deliveredAt: null }),
    ]);
    expect(kpis).toMatchObject({
      orders: 3,
      delivered: 2,
      cancelled: 1,
      gmv: 8000,
      sales: 7000,
      avgTicket: 4000,
      customers: 2,
    });
  });

  it('cuenta como nuevos a quienes pidieron por primera vez en el rango', () => {
    const first = new Map([
      ['alex', at('2026-09-01T10:00:00')],
      ['rosa', at('2026-10-05T18:00:00')],
    ]);
    expect(report([order(), order({ customerId: 'rosa' })], [], first).kpis.newCustomers).toBe(1);
  });

  it('llena todos los días del rango y las 24 horas', () => {
    const { byDay, byHour } = report([order(), order({ createdAt: at('2026-10-06T13:30:00') })]);
    expect(byDay).toEqual([
      { date: '2026-10-05', orders: 1, delivered: 1, cancelled: 0, gmv: 3500 },
      { date: '2026-10-06', orders: 1, delivered: 1, cancelled: 0, gmv: 3500 },
    ]);
    expect(byHour).toHaveLength(24);
    expect(byHour[18].orders).toBe(1);
    expect(byHour[13].orders).toBe(1);
  });

  it('separa las cancelaciones por quién y agrupa los motivos sin importar mayúsculas', () => {
    const { cancellations } = report([
      order({ status: OrderStatus.CANCELLED, cancelledBy: null }),
      order({ status: OrderStatus.CANCELLED, cancelledBy: Role.MERCHANT, cancelReason: 'Se acabó el pollo' }),
      order({ status: OrderStatus.CANCELLED, cancelledBy: Role.MERCHANT, cancelReason: 'se acabó el pollo ' }),
    ]);
    expect(cancellations.byWho).toEqual([
      { who: Role.MERCHANT, orders: 2 },
      { who: 'SYSTEM', orders: 1 },
    ]);
    expect(cancellations.reasons).toEqual([{ reason: 'Se acabó el pollo', orders: 2 }]);
  });

  it('mide medianas de respuesta, preparación, entrega y total; los programados no cuentan en el total', () => {
    const scheduled = order({ scheduledFor: at('2026-10-05T21:00:00'), deliveredAt: at('2026-10-05T21:05:00') });
    const { times } = report([order(), order(), scheduled]);
    expect(times).toEqual({ response: 2, preparation: 20, delivery: 18, total: 40 });
  });

  it('ordena negocios, productos y repartidores principales', () => {
    const result = report([
      order(),
      order({
        storeId: 'queso',
        storeName: 'Quesos',
        subtotal: 9000,
        items: [{ productName: 'Queso', quantity: 1, subtotal: 9000 }],
      }),
    ]);
    expect(result.topStores.map((s) => s.id)).toEqual(['queso', 'pollos']);
    expect(result.topProducts[0]).toEqual({ name: '1/4 de pollo', quantity: 2, sales: 3000 });
    expect(result.topCouriers).toEqual([{ id: 'luis', name: 'Luis Q.', deliveries: 2, minutes: 18 }]);
  });

  it('agrupa métodos de pago y cupones', () => {
    const result = report([
      order({ couponCode: 'ESPINAR', discountTotal: 300 }),
      order({ paymentMethod: PaymentMethodType.YAPE }),
    ]);
    expect(result.payments).toEqual([
      { method: PaymentMethodType.CASH, orders: 1, amount: 3500 },
      { method: PaymentMethodType.YAPE, orders: 1, amount: 3500 },
    ]);
    expect(result.coupons).toEqual([{ code: 'ESPINAR', orders: 1, discount: 300 }]);
  });
});

describe('median', () => {
  it('con número par promedia los del medio', () => {
    expect(median([1, 9, 3, 5])).toBe(4);
    expect(median([])).toBeNull();
  });
});
