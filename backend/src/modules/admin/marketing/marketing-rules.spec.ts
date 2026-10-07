import { CouponType } from '../../../generated/prisma/enums';
import { couponValue, normalizeCode, periodErrors } from './marketing-rules';

describe('couponValue', () => {
  it('guarda el porcentaje o los céntimos según el tipo', () => {
    expect(couponValue({ type: CouponType.PERCENTAGE, percentOff: 15, maxDiscount: 800 })).toEqual({ value: 15 });
    expect(couponValue({ type: CouponType.FIXED_AMOUNT, amountOff: 500 })).toEqual({ value: 500 });
    expect(couponValue({ type: CouponType.FREE_DELIVERY })).toEqual({ value: 0 });
  });

  it('rechaza datos que no calzan con el tipo', () => {
    expect(couponValue({ type: CouponType.PERCENTAGE })).toEqual({
      errors: { percentOff: 'Indica el porcentaje de descuento.' },
    });
    expect(couponValue({ type: CouponType.FIXED_AMOUNT, amountOff: 500, maxDiscount: 300 })).toEqual({
      errors: { maxDiscount: 'El tope solo aplica a cupones de porcentaje.' },
    });
    expect(couponValue({ type: CouponType.FREE_DELIVERY, amountOff: 100 })).toEqual({
      errors: { type: 'Envío gratis no lleva monto ni porcentaje.' },
    });
  });
});

describe('normalizeCode y periodErrors', () => {
  it('el código va en mayúsculas', () => {
    expect(normalizeCode('  bienvenida ')).toBe('BIENVENIDA');
  });

  it('el fin va después del inicio', () => {
    const start = new Date('2026-10-01T00:00:00Z');
    expect(periodErrors(start, new Date('2026-10-31T00:00:00Z'))).toEqual({});
    expect(periodErrors(start, start)).toEqual({ endsAt: 'La fecha de fin debe ser posterior al inicio.' });
  });
});
