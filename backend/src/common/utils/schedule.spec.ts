import { isOpenAt, nextOpeningAt, OpeningHours } from './schedule';

const MONDAY = 1;
const TUESDAY = 2;
const at = (dayOfWeek: number, hh: number, mm = 0) => ({ dayOfWeek, minutes: hh * 60 + mm });

describe('isOpenAt', () => {
  const lunch: OpeningHours[] = [{ dayOfWeek: MONDAY, opensAt: 11 * 60, closesAt: 23 * 60 }];

  it('abre en opensAt y cierra justo en closesAt', () => {
    expect(isOpenAt(lunch, at(MONDAY, 11))).toBe(true);
    expect(isOpenAt(lunch, at(MONDAY, 22, 59))).toBe(true);
    expect(isOpenAt(lunch, at(MONDAY, 23))).toBe(false);
    expect(isOpenAt(lunch, at(MONDAY, 10, 59))).toBe(false);
  });

  it('no abre en un día sin horario', () => {
    expect(isOpenAt(lunch, at(TUESDAY, 12))).toBe(false);
  });

  it('closesAt = 1440 cubre hasta la medianoche', () => {
    expect(isOpenAt([{ dayOfWeek: MONDAY, opensAt: 660, closesAt: 1440 }], at(MONDAY, 23, 59))).toBe(true);
  });

  it('un turno que cruza la medianoche sigue abierto la madrugada siguiente', () => {
    const night: OpeningHours[] = [{ dayOfWeek: MONDAY, opensAt: 20 * 60, closesAt: 2 * 60 }];
    expect(isOpenAt(night, at(MONDAY, 23))).toBe(true);
    expect(isOpenAt(night, at(TUESDAY, 1, 30))).toBe(true);
    expect(isOpenAt(night, at(TUESDAY, 2))).toBe(false);
    expect(isOpenAt(night, at(MONDAY, 1))).toBe(false);
  });

  it('el turno del sábado que cruza la medianoche sigue el domingo', () => {
    expect(isOpenAt([{ dayOfWeek: 6, opensAt: 1200, closesAt: 60 }], at(0, 0, 30))).toBe(true);
  });
});

describe('nextOpeningAt', () => {
  const lima = 'America/Lima';
  const lunch: OpeningHours[] = [{ dayOfWeek: MONDAY, opensAt: 11 * 60, closesAt: 23 * 60 }];

  it('hoy más tarde si todavía no abrió', () => {
    // Lunes 21 a las 08:15 en Lima → abre a las 11:00 (16:00 UTC).
    expect(nextOpeningAt(lunch, new Date('2026-09-21T13:15:00Z'), lima)).toEqual(new Date('2026-09-21T16:00:00Z'));
  });

  it('la semana siguiente si ya cerró el único día que abre', () => {
    // Lunes 21 a las 23:30 en Lima → lunes 28 a las 11:00.
    expect(nextOpeningAt(lunch, new Date('2026-09-22T04:30:00Z'), lima)).toEqual(new Date('2026-09-28T16:00:00Z'));
  });

  it('el día siguiente con el turno más temprano', () => {
    const week: OpeningHours[] = [
      { dayOfWeek: TUESDAY, opensAt: 18 * 60, closesAt: 22 * 60 },
      { dayOfWeek: TUESDAY, opensAt: 7 * 60, closesAt: 12 * 60 },
    ];
    // Lunes 21 a las 20:00 en Lima → martes 22 a las 07:00.
    expect(nextOpeningAt(week, new Date('2026-09-22T01:00:00Z'), lima)).toEqual(new Date('2026-09-22T12:00:00Z'));
  });

  it('null si no tiene horario', () => {
    expect(nextOpeningAt([], new Date('2026-09-21T13:15:00Z'), lima)).toBeNull();
  });
});
