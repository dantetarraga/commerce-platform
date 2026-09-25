import { CouponType } from '../../generated/prisma/enums';

export interface DiscountableCoupon {
  type: CouponType;
  value: number;
  maxDiscount: number | null;
}

/**
 * Descuento en céntimos. Nunca supera lo que descuenta: el subtotal
 * (monto fijo o porcentaje) o el delivery (delivery gratis).
 */
export function couponDiscount(coupon: DiscountableCoupon, amounts: { subtotal: number; deliveryFee: number }): number {
  switch (coupon.type) {
    case CouponType.FIXED_AMOUNT:
      return Math.min(coupon.value, amounts.subtotal);
    case CouponType.PERCENTAGE: {
      const discount = Math.round((amounts.subtotal * coupon.value) / 100);
      return Math.min(discount, coupon.maxDiscount ?? discount, amounts.subtotal);
    }
    case CouponType.FREE_DELIVERY:
      return amounts.deliveryFee;
  }
}
