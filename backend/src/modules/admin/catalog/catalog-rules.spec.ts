import { freeSlug, optionErrors, scheduleErrors, slugify, syncPlan } from './catalog-rules';

describe('slugify', () => {
  it('quita tildes, mayúsculas y signos', () => {
    expect(slugify('  Pollería Don Julián & Hijos! ')).toBe('polleria-don-julian-hijos');
  });

  it('elige el primer slug libre', () => {
    expect(freeSlug('kana', new Set())).toBe('kana');
    expect(freeSlug('kana', new Set(['kana', 'kana-2']))).toBe('kana-3');
  });
});

describe('scheduleErrors', () => {
  const MONDAY = 1;

  it('acepta turnos partidos el mismo día', () => {
    expect(
      scheduleErrors([
        { dayOfWeek: MONDAY, opensAt: 420, closesAt: 720 },
        { dayOfWeek: MONDAY, opensAt: 1080, closesAt: 1380 },
      ]),
    ).toEqual({});
  });

  it('rechaza turnos que se pisan', () => {
    expect(
      scheduleErrors([
        { dayOfWeek: MONDAY, opensAt: 420, closesAt: 900 },
        { dayOfWeek: MONDAY, opensAt: 840, closesAt: 1380 },
      ]),
    ).toEqual({ 'schedules.1': 'Este turno se cruza con otro.' });
  });

  it('un turno que cruza la medianoche choca con el temprano del día siguiente', () => {
    expect(
      scheduleErrors([
        { dayOfWeek: MONDAY, opensAt: 1200, closesAt: 120 },
        { dayOfWeek: MONDAY + 1, opensAt: 60, closesAt: 600 },
      ]),
    ).toEqual({ 'schedules.1': 'Este turno se cruza con otro.' });
  });

  it('el sábado que cruza la medianoche choca con el domingo temprano', () => {
    expect(
      Object.keys(
        scheduleErrors([
          { dayOfWeek: 6, opensAt: 1200, closesAt: 120 },
          { dayOfWeek: 0, opensAt: 60, closesAt: 600 },
        ]),
      ),
    ).toHaveLength(1);
  });

  it('rechaza un turno que abre y cierra a la misma hora', () => {
    expect(scheduleErrors([{ dayOfWeek: MONDAY, opensAt: 600, closesAt: 600 }])).toEqual({
      'schedules.0': 'El turno debe abrir y cerrar a horas distintas.',
    });
  });
});

describe('optionErrors', () => {
  it('pide que el grupo se pueda cumplir', () => {
    expect(
      optionErrors([
        { name: 'Cremas', minSelect: 0, maxSelect: 3, values: [1, 2, 3] },
        { name: 'Bebida', minSelect: 2, maxSelect: 1, values: [1, 2] },
        { name: 'Salsas', minSelect: 0, maxSelect: 3, values: [1] },
      ]),
    ).toEqual({
      'options.1.minSelect': 'El mínimo no puede ser mayor que el máximo.',
      'options.2.maxSelect': '"Salsas" tiene menos valores que el máximo a elegir.',
    });
  });
});

describe('syncPlan', () => {
  it('actualiza los que traen id, crea los nuevos y borra los que faltan', () => {
    const plan = syncPlan(['a', 'b', 'c'], [{ id: 'a', name: 'A' }, { name: 'Nuevo' }, { id: 'zz', name: '?' }]);
    expect(plan.update).toEqual([{ id: 'a', name: 'A' }]);
    expect(plan.create).toEqual([{ name: 'Nuevo' }]);
    expect(plan.remove).toEqual(['b', 'c']);
    expect(plan.unknownIds).toEqual(['zz']);
  });
});
