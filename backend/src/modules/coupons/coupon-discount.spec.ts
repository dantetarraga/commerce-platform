import { CouponType } from '../../generated/prisma/enums';
import { couponDiscount } from './coupon-discount';

const amounts = { subtotal: 2000, deliveryFee: 350 };

describe('couponDiscount', () => {
  it('monto fijo, sin pasar el subtotal', () => {
    expect(couponDiscount({ type: CouponType.FIXED_AMOUNT, value: 500, maxDiscount: null }, amounts)).toBe(500);
    expect(couponDiscount({ type: CouponType.FIXED_AMOUNT, value: 5000, maxDiscount: null }, amounts)).toBe(2000);
  });

  it('porcentaje con tope', () => {
    expect(couponDiscount({ type: CouponType.PERCENTAGE, value: 15, maxDiscount: null }, amounts)).toBe(300);
    expect(couponDiscount({ type: CouponType.PERCENTAGE, value: 15, maxDiscount: 200 }, amounts)).toBe(200);
  });

  it('delivery gratis descuenta el delivery', () => {
    expect(couponDiscount({ type: CouponType.FREE_DELIVERY, value: 0, maxDiscount: null }, amounts)).toBe(350);
  });
});
