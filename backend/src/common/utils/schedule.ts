export interface OpeningHours {
  dayOfWeek: number; // 0 = domingo … 6 = sábado
  opensAt: number; // minutos desde 00:00
  closesAt: number; // 1440 = medianoche; si es menor que opensAt, cruza la medianoche
}

export interface LocalTime {
  dayOfWeek: number;
  minutes: number;
}

const WEEKDAYS: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };

/** Día de la semana y minuto del día de `date` en la zona horaria de la ciudad. */
export function localTime(date: Date, timeZone: string): LocalTime {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const part = (type: Intl.DateTimeFormatPartTypes) => parts.find((p) => p.type === type)?.value ?? '';
  return {
    dayOfWeek: WEEKDAYS[part('weekday')],
    minutes: Number(part('hour')) * 60 + Number(part('minute')),
  };
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

/**
 * Próxima apertura después de `now` según el horario, o `null` si no abre en la
 * semana. Se suma al instante actual (sin convertir zonas): la ciudad no tiene
 * horario de verano.
 */
export function nextOpeningAt(schedules: readonly OpeningHours[], now: Date, timeZone: string): Date | null {
  const today = localTime(now, timeZone);
  for (let offset = 0; offset <= 7; offset++) {
    const day = (today.dayOfWeek + offset) % 7;
    const opens = schedules
      .filter((h) => h.dayOfWeek === day && (offset > 0 || h.opensAt > today.minutes))
      .map((h) => h.opensAt);
    if (opens.length) {
      const minutesAhead = offset * 1440 + Math.min(...opens) - today.minutes;
      const startOfMinute = Math.floor(now.getTime() / 60_000) * 60_000;
      return new Date(startOfMinute + minutesAhead * 60_000);
    }
  }
  return null;
}
