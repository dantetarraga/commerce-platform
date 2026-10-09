import { deliverySlots } from './delivery-slots';

const LIMA = 'America/Lima';
const lima = (iso: string) => new Date(`${iso}-05:00`);
const hhmm = (at: Date) =>
  at.toLocaleTimeString('es-PE', { timeZone: LIMA, hour: '2-digit', minute: '2-digit', hour12: false });

// Viernes 9 de octubre de 2026. Pollería: 12:00–22:00 todos los días menos el lunes.
const POLLERIA = [0, 2, 3, 4, 5, 6].map((dayOfWeek) => ({ dayOfWeek, opensAt: 12 * 60, closesAt: 22 * 60 }));

describe('deliverySlots', () => {
  it('ofrece el día completo en que atiende, cada 15 min, también mañana', () => {
    const days = deliverySlots(POLLERIA, lima('2026-10-09T08:00:00'), LIMA);
    expect(days.map((d) => d.date)).toEqual(['2026-10-09', '2026-10-10', '2026-10-11']);
    const tomorrow = days[1].slots.map(hhmm);
    expect(tomorrow[0]).toBe('12:00');
    expect(tomorrow.at(-1)).toBe('21:45');
    expect(tomorrow).toHaveLength(40);
  });

  it('empieza 45 min después de ahora', () => {
    const [today] = deliverySlots(POLLERIA, lima('2026-10-09T18:10:00'), LIMA);
    expect(hhmm(today.slots[0])).toBe('19:00');
  });

  it('deja vacío el día en que cierra', () => {
    // Domingo 11: mañana lunes no atiende.
    const days = deliverySlots(POLLERIA, lima('2026-10-11T10:00:00'), LIMA);
    expect(days[1]).toEqual({ date: '2026-10-12', slots: [] });
  });

  it('respeta los turnos que cruzan la medianoche', () => {
    // Abre el viernes de 20:00 a 2:00 del sábado.
    const bar = [{ dayOfWeek: 5, opensAt: 20 * 60, closesAt: 2 * 60 }];
    const [friday, saturday] = deliverySlots(bar, lima('2026-10-09T12:00:00'), LIMA);
    expect(hhmm(friday.slots[0])).toBe('20:00');
    expect(hhmm(friday.slots.at(-1)!)).toBe('23:45');
    expect(saturday.slots.map(hhmm)).toEqual(['00:00', '00:15', '00:30', '00:45', '01:00', '01:15', '01:30', '01:45']);
  });
});
