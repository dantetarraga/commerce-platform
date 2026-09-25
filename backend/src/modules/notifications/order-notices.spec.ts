import { OrderStatus } from '../../generated/prisma/enums';
import { orderNotice } from './order-notices';

const order = { orderId: 'ord_1', code: '#2481', storeId: 'st_1', storeName: 'Doña Rosa' };

describe('orderNotice', () => {
  it('confirmado y en preparación nombran al negocio y el código', () => {
    expect(orderNotice(OrderStatus.CONFIRMED, order)).toEqual({
      title: 'Pedido confirmado',
      body: 'Doña Rosa recibió tu pedido #2481',
      data: { kind: 'ORDER_CONFIRMED', orderId: 'ord_1' },
    });
    expect(orderNotice(OrderStatus.PREPARING, order)?.data.kind).toBe('PREPARING');
  });

  it('el repartidor aparece por su nombre', () => {
    const courier = { firstName: 'Luis', vehicleLabel: 'Moto roja' };
    expect(orderNotice(OrderStatus.COURIER_ASSIGNED, { ...order, courier })).toMatchObject({
      title: 'Luis va por tu pedido',
      body: 'Moto roja · lo recoge en Doña Rosa',
    });
    expect(orderNotice(OrderStatus.ON_THE_WAY, { ...order, courier })?.data.kind).toBe('COURIER_NEARBY');
  });

  it('entregado lleva al negocio', () => {
    expect(orderNotice(OrderStatus.DELIVERED, order)?.data).toEqual({
      kind: 'DELIVERED',
      orderId: 'ord_1',
      storeId: 'st_1',
    });
  });

  it('cancelado explica el motivo y que no se cobró', () => {
    expect(orderNotice(OrderStatus.CANCELLED, { ...order, cancelReason: 'Se acabó el pollo' })?.body).toBe(
      'Doña Rosa: Se acabó el pollo. No se te cobró nada.',
    );
  });

  it('recibido y listo no avisan', () => {
    expect(orderNotice(OrderStatus.RECEIVED, order)).toBeNull();
    expect(orderNotice(OrderStatus.READY, order)).toBeNull();
  });
});
