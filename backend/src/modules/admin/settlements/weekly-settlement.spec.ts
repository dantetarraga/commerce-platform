import { owedTo, settlementStatus, settleWeek, SettlementOrder } from './weekly-settlement';

const OWNER = 'u_owner';
const order = (over: Partial<SettlementOrder> = {}): SettlementOrder => ({
  id: 'o1',
  code: '#1',
  deliveredAt: new Date('2026-10-06T15:00:00Z'),
  subtotal: 4200,
  commissionRateBps: 1000,
  collectedById: 'u_courier',
  collectedAmount: 4550,
  ...over,
});

describe('settleWeek', () => {
  it('sin pedidos, todo en cero', () => {
    expect(settleWeek([], { ownerId: OWNER, fallbackRateBps: 1000 })).toMatchObject({
      delivered: 0,
      sales: 0,
      commission: 0,
      collectedByStore: 0,
      balance: 0,
    });
  });

  it('cobra el repartidor: el negocio recibe lo vendido menos la comisión', () => {
    const result = settleWeek([order(), order({ id: 'o2', subtotal: 1500, commissionRateBps: 800 })], {
      ownerId: OWNER,
      fallbackRateBps: 1000,
    });
    expect(result).toMatchObject({ delivered: 2, sales: 5700, commission: 420 + 120, collectedByStore: 0 });
    expect(result.balance).toBe(5700 - 540);
    expect(owedTo(result.balance)).toBe('STORE');
  });

  it('respeta la tasa guardada en cada pedido y usa la de respaldo si falta', () => {
    const result = settleWeek([order({ commissionRateBps: null }), order({ id: 'o2', commissionRateBps: 500 })], {
      ownerId: OWNER,
      fallbackRateBps: 1200,
    });
    expect(result.orders.map((o) => [o.rateBps, o.commission])).toEqual([
      [1200, 504],
      [500, 210],
    ]);
  });

  it('lo que cobró el propio negocio se descuenta y puede dejar el saldo a favor de Apamuy', () => {
    const result = settleWeek([order({ collectedById: OWNER, collectedAmount: 4550 })], {
      ownerId: OWNER,
      fallbackRateBps: 1000,
    });
    expect(result.collectedByStore).toBe(4550);
    expect(result.balance).toBe(4200 - 420 - 4550);
    expect(owedTo(result.balance)).toBe('APAMUY');
  });

  it('ordena los pedidos por hora de entrega', () => {
    const result = settleWeek(
      [order({ id: 'late', deliveredAt: new Date('2026-10-08T12:00:00Z') }), order({ id: 'early' })],
      { ownerId: OWNER, fallbackRateBps: 1000 },
    );
    expect(result.orders.map((o) => o.id)).toEqual(['early', 'late']);
  });
});

describe('settlementStatus', () => {
  const end = new Date('2026-10-12T05:00:00Z');

  it('abierta mientras corre la semana, pendiente después, pagada al marcarla', () => {
    expect(settlementStatus(end, new Date('2026-10-11T20:00:00Z'), false, 3)).toBe('OPEN');
    expect(settlementStatus(end, end, false, 3)).toBe('PENDING');
    expect(settlementStatus(end, new Date('2026-10-11T20:00:00Z'), true, 3)).toBe('PAID');
  });

  it('una semana terminada sin entregas no queda por pagar', () => {
    expect(settlementStatus(end, end, false, 0)).toBe('EMPTY');
    expect(settlementStatus(end, new Date('2026-10-11T20:00:00Z'), false, 0)).toBe('OPEN');
  });

  it('owedTo es null si el saldo es cero', () => {
    expect(owedTo(0)).toBeNull();
  });
});
