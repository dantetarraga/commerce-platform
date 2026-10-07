import { DateTime } from 'luxon';
import { DayRange, LocalTime, ZonedTime } from './zoned-time';

export class LuxonZonedTime implements ZonedTime {
  localTime(at: Date, timeZone: string): LocalTime {
    const local = this.zoned(at, timeZone);
    return { dayOfWeek: local.weekday % 7, minutes: local.hour * 60 + local.minute };
  }

  localDate(at: Date, timeZone: string): string {
    return this.zoned(at, timeZone).toISODate()!;
  }

  dayRange(date: string, timeZone: string): DayRange {
    const start = DateTime.fromISO(date, { zone: timeZone }).startOf('day');
    if (!start.isValid) throw new RangeError(`Fecha inválida: ${date}`);
    return { start: start.toJSDate(), end: start.plus({ days: 1 }).toJSDate() };
  }

  atLocalMinute(at: Date, timeZone: string, daysAhead: number, minuteOfDay: number): Date {
    return this.zoned(at, timeZone)
      .startOf('day')
      .plus({ days: daysAhead })
      .set({ hour: Math.floor(minuteOfDay / 60), minute: minuteOfDay % 60 })
      .toJSDate();
  }

  private zoned(at: Date, timeZone: string): DateTime {
    const local = DateTime.fromJSDate(at, { zone: timeZone });
    if (!local.isValid) throw new RangeError(`Zona horaria inválida: ${timeZone}`);
    return local;
  }
}
