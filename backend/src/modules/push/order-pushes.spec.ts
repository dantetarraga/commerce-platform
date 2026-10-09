import { OrderStatus, Role } from '../../generated/prisma/enums';
import { orderPushes, PushOrder } from './order-pushes';

const order: PushOrder = {
  id: 'or_1',
  code: '#2481',
  storeId: 'st_1',
  storeName: 'Doña Rosa',
  cancelReason: null,
  cancelledBy: null,
  courier: null,
};

const audiences = (status: OrderStatus, overrides: Partial<PushOrder> = {}) =>
  orderPushes({ ...order, ...overrides }, status).map((push) => push.audience);

describe('orderPushes', () => {
  it('un pedido nuevo suena como alarma en el negocio, solo con datos y con vencimiento', () => {
    const [push] = orderPushes(order, OrderStatus.RECEIVED);
    expect(push.audience).toBe('owner');
    expect(push.message).toMatchObject({ channel: 'order_alarm', ttlSeconds: 480, data: { type: 'NEW_ORDER' } });
    expect(push.message.title).toBeUndefined();
  });

  it('al cliente le llega el mismo aviso que ve en la app', () => {
    const [push] = orderPushes(order, OrderStatus.CONFIRMED);
    expect(push).toMatchObject({
      audience: 'customer',
      message: { title: 'Pedido confirmado', data: { kind: 'ORDER_CONFIRMED', orderId: 'or_1' } },
    });
  });

  it('listo para recoger avisa a los repartidores de la ciudad', () => {
    expect(audiences(OrderStatus.READY)).toEqual(['couriers']);
  });

  it('si cancela el cliente, solo se entera el negocio; si cancela el negocio, solo el cliente', () => {
    expect(audiences(OrderStatus.CANCELLED, { cancelledBy: Role.CUSTOMER })).toEqual(['owner']);
    expect(audiences(OrderStatus.CANCELLED, { cancelledBy: Role.MERCHANT, cancelReason: 'Sin pollo' })).toEqual([
      'customer',
    ]);
  });

  it('la cancelación automática avisa a los dos', () => {
    expect(
      audiences(OrderStatus.CANCELLED, { cancelledBy: null, cancelReason: 'el negocio no respondió a tiempo' }),
    ).toEqual(['customer', 'owner']);
  });
});
