import { addDays, settlementWeek, weekStartOf } from './settlement-week';

describe('weekStartOf', () => {
  it('lleva cualquier día al lunes de su semana', () => {
    expect(weekStartOf('2026-10-05')).toBe('2026-10-05'); // lunes
    expect(weekStartOf('2026-10-08')).toBe('2026-10-05'); // jueves
    expect(weekStartOf('2026-10-11')).toBe('2026-10-05'); // domingo
    expect(weekStartOf('2026-10-12')).toBe('2026-10-12');
  });

  it('cruza meses y años', () => {
    expect(weekStartOf('2026-11-01')).toBe('2026-10-26');
    expect(weekStartOf('2027-01-01')).toBe('2026-12-28');
  });
});

describe('settlementWeek', () => {
  it('da el domingo y las semanas vecinas', () => {
    expect(settlementWeek('2026-10-08')).toEqual({
      start: '2026-10-05',
      end: '2026-10-11',
      previous: '2026-09-28',
      next: '2026-10-12',
    });
  });

  it('addDays suma días de calendario', () => {
    expect(addDays('2026-02-27', 2)).toBe('2026-03-01');
  });
});
