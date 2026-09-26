import { PaymentMethodType } from '../../generated/prisma/enums';

export type CollectedMethod = Exclude<PaymentMethodType, 'CARD'>;

export interface CollectedTotals {
  total: number;
  CASH: number;
  YAPE: number;
  PLIN: number;
}

/**
 * Lo cobrado por el repartidor, en céntimos, total y por método. Solo cuenta
 * lo que registró al entregar (un pago sin registro no suma).
 */
export function sumCollected(
  payments: readonly { collectedMethod: PaymentMethodType | null; collectedAmount: number | null }[],
): CollectedTotals {
  const totals: CollectedTotals = { total: 0, CASH: 0, YAPE: 0, PLIN: 0 };
  for (const { collectedMethod, collectedAmount } of payments) {
    if (!collectedMethod || collectedMethod === PaymentMethodType.CARD || collectedAmount === null) continue;
    totals[collectedMethod] += collectedAmount;
    totals.total += collectedAmount;
  }
  return totals;
}
