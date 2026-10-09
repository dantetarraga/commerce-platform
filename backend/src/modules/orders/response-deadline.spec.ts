import { expiredBefore, responseAlert, responseClockStart, waitingMinutes } from './response-deadline';

const at = (iso: string) => new Date(iso);

describe('plazo de respuesta del negocio', () => {
  const placed = { createdAt: at('2026-10-08T12:00:00Z'), scheduledFor: null };

  it('cuenta desde que se crea el pedido y avisa a los 3 minutos', () => {
    expect(waitingMinutes(placed, at('2026-10-08T12:02:59Z'))).toBe(2);
    expect(responseAlert(placed, at('2026-10-08T12:02:59Z'))).toBeNull();
    expect(responseAlert(placed, at('2026-10-08T12:03:00Z'))).toBe('late');
  });

  it('un programado empieza a contar 60 minutos antes de la hora pedida', () => {
    const scheduled = { createdAt: at('2026-10-08T12:00:00Z'), scheduledFor: at('2026-10-08T15:00:00Z') };
    expect(responseClockStart(scheduled)).toEqual(at('2026-10-08T14:00:00Z'));
    expect(waitingMinutes(scheduled, at('2026-10-08T13:00:00Z'))).toBe(0);
  });

  it('si se programó para dentro de menos de una hora, cuenta desde que se creó', () => {
    const soon = { createdAt: at('2026-10-08T12:00:00Z'), scheduledFor: at('2026-10-08T12:30:00Z') };
    expect(responseClockStart(soon)).toEqual(soon.createdAt);
  });

  it('el filtro de vencidos usa 8 minutos, corridos 60 para los programados', () => {
    expect(expiredBefore(at('2026-10-08T12:08:00Z'))).toEqual({
      createdAt: { lte: at('2026-10-08T12:00:00Z') },
      OR: [{ scheduledFor: null }, { scheduledFor: { lte: at('2026-10-08T13:00:00Z') } }],
    });
  });
});
