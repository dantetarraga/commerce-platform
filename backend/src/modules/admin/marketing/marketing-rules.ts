import { CouponType } from '../../../generated/prisma/enums';

/** Cómo se guarda el descuento según el tipo: `value` es % o céntimos (0 para envío gratis). */
export interface CouponTerms {
  type: CouponType;
  percentOff?: number;
  amountOff?: number;
  maxDiscount?: number | null;
}

/** Errores por campo si el descuento no calza con su tipo; si no, el `value` a guardar. */
export function couponValue(terms: CouponTerms): { value: number } | { errors: Record<string, string> } {
  switch (terms.type) {
    case CouponType.PERCENTAGE:
      if (terms.percentOff === undefined) return { errors: { percentOff: 'Indica el porcentaje de descuento.' } };
      if (terms.amountOff !== undefined)
        return { errors: { amountOff: 'Un cupón de porcentaje no lleva monto fijo.' } };
      return { value: terms.percentOff };
    case CouponType.FIXED_AMOUNT:
      if (terms.amountOff === undefined) return { errors: { amountOff: 'Indica cuánto descuenta.' } };
      if (terms.percentOff !== undefined)
        return { errors: { percentOff: 'Un cupón de monto fijo no lleva porcentaje.' } };
      if (terms.maxDiscount != null) return { errors: { maxDiscount: 'El tope solo aplica a cupones de porcentaje.' } };
      return { value: terms.amountOff };
    case CouponType.FREE_DELIVERY:
      if (terms.percentOff !== undefined || terms.amountOff !== undefined || terms.maxDiscount != null) {
        return { errors: { type: 'Envío gratis no lleva monto ni porcentaje.' } };
      }
      return { value: 0 };
  }
}

/** `CODIGO` en mayúsculas, sin espacios. */
export const normalizeCode = (code: string) => code.trim().toUpperCase();

export function periodErrors(startsAt: Date, endsAt: Date): Record<string, string> {
  return endsAt > startsAt ? {} : { endsAt: 'La fecha de fin debe ser posterior al inicio.' };
}
