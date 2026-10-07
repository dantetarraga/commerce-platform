/** Día de la semana (0 = domingo … 6 = sábado) y minuto del día en una zona horaria. */
export interface LocalTime {
  dayOfWeek: number;
  minutes: number;
}

/** Rango `[start, end)` en UTC. */
export interface DayRange {
  start: Date;
  end: Date;
}

/**
 * Operaciones con fechas en la zona horaria de una ciudad. El backend solo usa
 * esta interfaz; la librería concreta vive en un adaptador (hoy Luxon).
 */
export interface ZonedTime {
  localTime(at: Date, timeZone: string): LocalTime;
  /** `YYYY-MM-DD` del día local en que cae `at`. */
  localDate(at: Date, timeZone: string): string;
  /** Inicio del día local `date` (`YYYY-MM-DD`) y del siguiente, en UTC. */
  dayRange(date: string, timeZone: string): DayRange;
  /** Instante del día local de `at` + `daysAhead` a `minuteOfDay` (minutos desde 00:00). */
  atLocalMinute(at: Date, timeZone: string, daysAhead: number, minuteOfDay: number): Date;
}
