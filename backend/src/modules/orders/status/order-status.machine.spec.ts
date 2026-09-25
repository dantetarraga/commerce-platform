import { OrderStatus as S, Role } from '../../../generated/prisma/enums';
import { canTransition, isFinal, nextStatus } from './order-status.machine';

describe('máquina de estados del pedido', () => {
  it('el negocio confirma, prepara y marca listo, en orden', () => {
    expect(canTransition(S.RECEIVED, S.CONFIRMED, Role.MERCHANT)).toBe(true);
    expect(canTransition(S.CONFIRMED, S.PREPARING, Role.MERCHANT)).toBe(true);
    expect(canTransition(S.PREPARING, S.READY, Role.MERCHANT)).toBe(true);
    expect(canTransition(S.RECEIVED, S.READY, Role.MERCHANT)).toBe(false);
  });

  it('el repartidor toma, sale y entrega; el negocio no', () => {
    expect(canTransition(S.READY, S.COURIER_ASSIGNED, Role.COURIER)).toBe(true);
    expect(canTransition(S.COURIER_ASSIGNED, S.ON_THE_WAY, Role.COURIER)).toBe(true);
    expect(canTransition(S.ON_THE_WAY, S.DELIVERED, Role.COURIER)).toBe(true);
    expect(canTransition(S.ON_THE_WAY, S.DELIVERED, Role.MERCHANT)).toBe(false);
    expect(canTransition(S.RECEIVED, S.CONFIRMED, Role.COURIER)).toBe(false);
  });

  it('el cliente no avanza estados', () => {
    expect(canTransition(S.RECEIVED, S.CONFIRMED, Role.CUSTOMER)).toBe(false);
  });

  it.each([
    [Role.CUSTOMER, S.CONFIRMED, true],
    [Role.CUSTOMER, S.PREPARING, false],
    [Role.MERCHANT, S.READY, true],
    [Role.MERCHANT, S.COURIER_ASSIGNED, false],
    [Role.COURIER, S.ON_THE_WAY, false],
    [Role.ADMIN, S.ON_THE_WAY, true],
    [Role.ADMIN, S.DELIVERED, false],
  ])('%s cancela en %s → %s', (role, from, expected) => {
    expect(canTransition(from, S.CANCELLED, role)).toBe(expected);
  });

  it('entregado y cancelado son finales', () => {
    expect(isFinal(S.DELIVERED)).toBe(true);
    expect(isFinal(S.CANCELLED)).toBe(true);
    expect(nextStatus(S.DELIVERED)).toBeUndefined();
    expect(nextStatus(S.READY)).toBe(S.COURIER_ASSIGNED);
  });
});
