import { LocalTime, zonedTime } from '../time';

export interface OpeningHours {
  dayOfWeek: number; // 0 = domingo … 6 = sábado
  opensAt: number; // minutos desde 00:00
  closesAt: number; // 1440 = medianoche; si es menor que opensAt, cruza la medianoche
}

export function isOpenAt(schedules: readonly OpeningHours[], at: LocalTime): boolean {
  return schedules.some(({ dayOfWeek, opensAt, closesAt }) => {
    if (closesAt > opensAt) {
      return at.dayOfWeek === dayOfWeek && at.minutes >= opensAt && at.minutes < closesAt;
    }
    // Turno que cruza la medianoche: la parte de hoy y la de mañana temprano.
    const nextDay = (dayOfWeek + 1) % 7;
    return (at.dayOfWeek === dayOfWeek && at.minutes >= opensAt) || (at.dayOfWeek === nextDay && at.minutes < closesAt);
  });
}

/** Próxima apertura después de `now` según el horario, o `null` si no abre en la semana. */
export function nextOpeningAt(schedules: readonly OpeningHours[], now: Date, timeZone: string): Date | null {
  const today = zonedTime.localTime(now, timeZone);
  for (let offset = 0; offset <= 7; offset++) {
    const day = (today.dayOfWeek + offset) % 7;
    const opens = schedules
      .filter((h) => h.dayOfWeek === day && (offset > 0 || h.opensAt > today.minutes))
      .map((h) => h.opensAt);
    if (opens.length) return zonedTime.atLocalMinute(now, timeZone, offset, Math.min(...opens));
  }
  return null;
}
