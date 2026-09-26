import { limaDate, limaDayRange } from './lima-day';

describe('limaDate', () => {
  it('usa el día de Lima, no el UTC', () => {
    expect(limaDate(new Date('2026-09-26T04:59:59Z'))).toBe('2026-09-25');
    expect(limaDate(new Date('2026-09-26T05:00:00Z'))).toBe('2026-09-26');
  });

  it('cruza fin de mes y de año', () => {
    expect(limaDate(new Date('2027-01-01T03:00:00Z'))).toBe('2026-12-31');
  });
});

describe('limaDayRange', () => {
  it('va de 05:00Z a 05:00Z del día siguiente', () => {
    const { start, end } = limaDayRange('2026-09-25');
    expect(start.toISOString()).toBe('2026-09-25T05:00:00.000Z');
    expect(end.toISOString()).toBe('2026-09-26T05:00:00.000Z');
  });

  it('contiene los instantes cuyo día de Lima es esa fecha', () => {
    const { start, end } = limaDayRange('2026-02-28');
    expect(end.toISOString()).toBe('2026-03-01T05:00:00.000Z');
    expect(limaDate(start)).toBe('2026-02-28');
    expect(limaDate(new Date(end.getTime() - 1))).toBe('2026-02-28');
  });
});
