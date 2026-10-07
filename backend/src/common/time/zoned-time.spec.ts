import { LuxonZonedTime } from './luxon-zoned-time';
import { ZonedTime } from './zoned-time';

// Contrato del adaptador: cualquier implementación nueva debe pasar estas pruebas.
const implementations: [string, ZonedTime][] = [['Luxon', new LuxonZonedTime()]];

describe.each(implementations)('ZonedTime (%s)', (_, time) => {
  const lima = 'America/Lima';

  it('localTime usa la zona de la ciudad, no la del servidor', () => {
    // 2026-09-22 03:30 UTC = lunes 21 a las 22:30 en Lima (UTC-5).
    expect(time.localTime(new Date('2026-09-22T03:30:00Z'), lima)).toEqual({ dayOfWeek: 1, minutes: 22 * 60 + 30 });
    // Domingo es 0.
    expect(time.localTime(new Date('2026-09-27T15:00:00Z'), lima).dayOfWeek).toBe(0);
  });

  it('localDate usa el día local, también al cruzar fin de año', () => {
    expect(time.localDate(new Date('2026-09-26T04:59:59Z'), lima)).toBe('2026-09-25');
    expect(time.localDate(new Date('2026-09-26T05:00:00Z'), lima)).toBe('2026-09-26');
    expect(time.localDate(new Date('2027-01-01T03:00:00Z'), lima)).toBe('2026-12-31');
  });

  it('dayRange va del inicio del día local al del siguiente', () => {
    const { start, end } = time.dayRange('2026-02-28', lima);
    expect(start.toISOString()).toBe('2026-02-28T05:00:00.000Z');
    expect(end.toISOString()).toBe('2026-03-01T05:00:00.000Z');
    expect(time.localDate(new Date(end.getTime() - 1), lima)).toBe('2026-02-28');
  });

  it('dayRange rechaza una fecha inválida', () => {
    expect(() => time.dayRange('2026-13-40', lima)).toThrow(RangeError);
  });

  it('atLocalMinute suma días locales y fija la hora', () => {
    const mondayNight = new Date('2026-09-22T04:30:00Z'); // lunes 21, 23:30 en Lima
    expect(time.atLocalMinute(mondayNight, lima, 0, 11 * 60).toISOString()).toBe('2026-09-21T16:00:00.000Z');
    expect(time.atLocalMinute(mondayNight, lima, 7, 11 * 60).toISOString()).toBe('2026-09-28T16:00:00.000Z');
  });

  it('respeta el horario de verano de otras zonas', () => {
    // Nueva York pasa a UTC-4 el 8 de marzo de 2026: las 09:00 locales cambian de hora UTC.
    const before = new Date('2026-03-07T12:00:00Z');
    expect(time.atLocalMinute(before, 'America/New_York', 0, 9 * 60).toISOString()).toBe('2026-03-07T14:00:00.000Z');
    expect(time.atLocalMinute(before, 'America/New_York', 2, 9 * 60).toISOString()).toBe('2026-03-09T13:00:00.000Z');
  });
});
