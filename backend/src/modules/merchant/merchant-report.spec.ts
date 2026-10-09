import { OrderStatus, PaymentMethodType } from '../../generated/prisma/enums';
import { eachDay, previousPeriod, rangeErrors, salesByDay, settlementByDay } from './merchant-report';

describe('reporte del negocio por rango', () => {
  it('recorre los días incluyendo los extremos, también entre meses', () => {
    expect(eachDay('2026-09-29', '2026-10-02')).toEqual(['2026-09-29', '2026-09-30', '2026-10-01', '2026-10-02']);
  });

  it('el periodo anterior tiene la misma duración y termina justo antes', () => {
    expect(previousPeriod('2026-10-01', '2026-10-07')).toEqual({ from: '2026-09-24', to: '2026-09-30' });
  });

  it('rechaza rangos invertidos o de más de 92 días', () => {
    expect(rangeErrors('2026-10-08', '2026-10-01')).toHaveProperty('to');
    expect(rangeErrors('2026-01-01', '2026-12-31')).toHaveProperty('to');
    expect(rangeErrors('2026-10-01', '2026-10-01')).toEqual({});
  });

  it('suma por día solo lo entregado y deja en cero los días sin pedidos', () => {
    const at = (iso: string) => new Date(iso);
    const orders = [
      { status: OrderStatus.DELIVERED, subtotal: 2000, createdAt: at('2026-10-01T15:00:00Z') },
      { status: OrderStatus.DELIVERED, subtotal: 1000, createdAt: at('2026-10-01T18:00:00Z') },
      { status: OrderStatus.CANCELLED, subtotal: 5000, createdAt: at('2026-10-01T19:00:00Z') },
    ];
    const rows = salesByDay(orders, ['2026-10-01', '2026-10-02'], (date) => date.toISOString().slice(0, 10));
    expect(rows).toEqual([
      { date: '2026-10-01', sales: 3000, delivered: 2, cancelled: 1 },
      { date: '2026-10-02', sales: 0, delivered: 0, cancelled: 0 },
    ]);
  });

  it('la rendición agrupa por día de entrega lo vendido y lo cobrado por método', () => {
    const dayOf = (date: Date) => date.toISOString().slice(0, 10);
    const rows = settlementByDay(
      [
        {
          subtotal: 2000,
          deliveredAt: new Date('2026-10-01T15:00:00Z'),
          collectedMethod: PaymentMethodType.CASH,
          collectedAmount: 2400,
        },
        {
          subtotal: 1000,
          deliveredAt: new Date('2026-10-01T16:00:00Z'),
          collectedMethod: PaymentMethodType.YAPE,
          collectedAmount: 1400,
        },
      ],
      ['2026-10-01', '2026-10-02'],
      dayOf,
    );
    expect(rows[0]).toEqual({
      date: '2026-10-01',
      delivered: 2,
      sales: 3000,
      collected: { total: 3800, CASH: 2400, YAPE: 1400, PLIN: 0 },
    });
    expect(rows[1].delivered).toBe(0);
  });
});
