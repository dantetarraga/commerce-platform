import { PaymentMethodType } from '../../../generated/prisma/enums';
import { CashOrder, cashReport } from './cash-report';

const ana = { id: 'co_ana', name: 'Ana', phone: '900000101' };
const luis = { id: 'co_luis', name: 'Luis', phone: '900000102' };

const order = (overrides: Partial<CashOrder>): CashOrder => ({
  storeId: 'st_pollos',
  storeName: 'Pollos Rosa',
  courier: ana,
  subtotal: 2000,
  deliveryFee: 400,
  tip: 0,
  total: 2400,
  collectedMethod: PaymentMethodType.CASH,
  collectedAmount: 2400,
  ...overrides,
});

describe('cashReport', () => {
  it('compara lo cobrado por cada repartidor con lo que debía cobrar', () => {
    const report = cashReport([
      order({}),
      order({ collectedMethod: PaymentMethodType.YAPE }),
      order({ courier: luis, collectedAmount: 2000 }),
    ]);
    expect(report.couriers).toEqual([
      {
        courierId: 'co_ana',
        name: 'Ana',
        phone: '900000101',
        delivered: 2,
        expected: 4800,
        collected: { total: 4800, CASH: 2400, YAPE: 2400, PLIN: 0 },
        difference: 0,
      },
      expect.objectContaining({ courierId: 'co_luis', expected: 2400, difference: -400 }),
    ]);
    expect(report.difference).toBe(-400);
  });

  it('por negocio cuenta lo vendido sin envío ni propina', () => {
    const report = cashReport([order({ tip: 300, total: 2700 }), order({ storeId: 'st_pizza', storeName: 'Pizza' })]);
    expect(report.stores.map((s) => [s.name, s.sales])).toEqual([
      ['Pizza', 2000],
      ['Pollos Rosa', 2000],
    ]);
    expect(report).toMatchObject({ delivered: 2, sales: 4000, deliveryFees: 800, tips: 300 });
  });

  it('un cobro no registrado cuenta como diferencia', () => {
    const report = cashReport([order({ collectedMethod: null, collectedAmount: null })]);
    expect(report.couriers[0].difference).toBe(-2400);
  });
});
