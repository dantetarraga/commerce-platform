import { PaymentMethodType } from '../../generated/prisma/enums';
import { sumCollected } from './courier-summary';

describe('sumCollected', () => {
  it('sin entregas, todo en cero', () => {
    expect(sumCollected([])).toEqual({ total: 0, CASH: 0, YAPE: 0, PLIN: 0 });
  });

  it('suma por método y en total', () => {
    expect(
      sumCollected([
        { collectedMethod: PaymentMethodType.CASH, collectedAmount: 3550 },
        { collectedMethod: PaymentMethodType.CASH, collectedAmount: 2000 },
        { collectedMethod: PaymentMethodType.YAPE, collectedAmount: 4200 },
        { collectedMethod: PaymentMethodType.PLIN, collectedAmount: 1000 },
      ]),
    ).toEqual({ total: 10750, CASH: 5550, YAPE: 4200, PLIN: 1000 });
  });

  it('ignora los pagos sin cobro registrado', () => {
    expect(
      sumCollected([
        { collectedMethod: null, collectedAmount: null },
        { collectedMethod: PaymentMethodType.YAPE, collectedAmount: 1500 },
      ]),
    ).toEqual({ total: 1500, CASH: 0, YAPE: 1500, PLIN: 0 });
  });
});
