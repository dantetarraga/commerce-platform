import { zonedTime } from '../../common/time';
import { isOpenAt, OpeningHours } from '../../common/utils/schedule';

/** Minutos mínimos entre ahora y una entrega programada (preparar y llevar). */
export const SCHEDULE_LEAD_MINUTES = 45;
const SLOT_MINUTES = 15;
const DAY_MINUTES = 24 * 60;

export interface DeliveryDay {
  /** `YYYY-MM-DD` en la hora de la ciudad. */
  date: string;
  /** Horas de llegada que se pueden elegir, cada 15 min; vacío si ese día no atiende. */
  slots: Date[];
}

/**
 * Horas para programar un pedido en los próximos [days] días: cada 15 min dentro
 * del horario del negocio y desde [SCHEDULE_LEAD_MINUTES] después de [now]. Usa la
 * misma regla que valida el pedido, así una hora ofrecida nunca se rechaza.
 */
export function deliverySlots(
  schedules: readonly OpeningHours[],
  now: Date,
  timeZone: string,
  days = 3,
): DeliveryDay[] {
  const earliest = now.getTime() + SCHEDULE_LEAD_MINUTES * 60_000;
  return Array.from({ length: days }, (_, daysAhead) => {
    const slots: Date[] = [];
    for (let minute = 0; minute < DAY_MINUTES; minute += SLOT_MINUTES) {
      const at = zonedTime.atLocalMinute(now, timeZone, daysAhead, minute);
      if (at.getTime() >= earliest && isOpenAt(schedules, zonedTime.localTime(at, timeZone))) slots.push(at);
    }
    return { date: zonedTime.localDate(zonedTime.atLocalMinute(now, timeZone, daysAhead, 0), timeZone), slots };
  });
}
