/** Puntos básicos: 100 = 1 %, 10 000 = 100 %. */
export const MAX_RATE_BPS = 10_000;

/** La del seed y la migración; se usa si falta la fila de `PlatformSettings`. */
export const FALLBACK_RATE_BPS = 1000;

/** La comisión propia del negocio, o la de Apamuy si no tiene una. */
export const effectiveRateBps = (storeRateBps: number | null, defaultRateBps: number) => storeRateBps ?? defaultRateBps;

/** Comisión en céntimos sobre el subtotal de productos (sin envío ni propina), redondeada al céntimo. */
export function commissionOf(subtotal: number, rateBps: number): number {
  return Math.round((subtotal * rateBps) / MAX_RATE_BPS);
}
