import { isOpenAt, localTime, OpeningHours } from './schedule';

const MONDAY = 1;
const TUESDAY = 2;
const at = (dayOfWeek: number, hh: number, mm = 0) => ({ dayOfWeek, minutes: hh * 60 + mm });

describe('localTime', () => {
  it('usa la zona horaria de la ciudad, no la del servidor', () => {
    // 2026-09-22 03:30 UTC = lunes 21 a las 22:30 en Lima (UTC-5).
    expect(localTime(new Date('2026-09-22T03:30:00Z'), 'America/Lima')).toEqual(at(MONDAY, 22, 30));
  });
});

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
