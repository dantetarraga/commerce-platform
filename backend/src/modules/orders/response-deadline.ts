/**
 * Plazo del negocio para responder un pedido nuevo (OPERACION §2): a los 3 minutos
 * se avisa al admin y a los 8 Apamuy lo cancela. En un pedido programado el plazo
 * empieza 60 minutos antes de la hora pedida, no al crearlo.
 */
export const ALERT_AFTER_MINUTES = 3;
export const EXPIRE_AFTER_MINUTES = 8;
export const SCHEDULED_LEAD_MINUTES = 60;

/** Lo que ve el cliente cuando el negocio no respondió. */
export const UNANSWERED_REASON = 'el negocio no respondió a tiempo';

const MINUTE = 60_000;

interface Timed {
  createdAt: Date;
  scheduledFor: Date | null;
}

export function responseClockStart(order: Timed): Date {
  if (!order.scheduledFor) return order.createdAt;
  const leadStart = new Date(order.scheduledFor.getTime() - SCHEDULED_LEAD_MINUTES * MINUTE);
  return leadStart > order.createdAt ? leadStart : order.createdAt;
}

/** Minutos enteros esperando respuesta; 0 si el plazo aún no empieza. */
export function waitingMinutes(order: Timed, now: Date): number {
  return Math.max(0, Math.floor((now.getTime() - responseClockStart(order).getTime()) / MINUTE));
}

/** `late` desde los 3 minutos sin respuesta: el admin debería llamar al negocio. */
export function responseAlert(order: Timed, now: Date): 'late' | null {
  return waitingMinutes(order, now) >= ALERT_AFTER_MINUTES ? 'late' : null;
}

/**
 * Filtro de los pedidos RECEIVED cuyo plazo ya venció: creados hace 8 minutos o más,
 * o programados cuya ventana de aceptación empezó hace 8 minutos o más.
 */
export function expiredBefore(now: Date) {
  const cutoff = new Date(now.getTime() - EXPIRE_AFTER_MINUTES * MINUTE);
  const scheduledCutoff = new Date(cutoff.getTime() + SCHEDULED_LEAD_MINUTES * MINUTE);
  return {
    createdAt: { lte: cutoff },
    OR: [{ scheduledFor: null }, { scheduledFor: { lte: scheduledCutoff } }],
  };
}
