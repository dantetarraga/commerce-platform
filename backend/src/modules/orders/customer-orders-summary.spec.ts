import { OrderStatus } from '../../generated/prisma/enums';
import { REPEAT_STORES, summarizeCustomerOrders } from './customer-orders-summary';

const order = (id: string, storeId: string, status: OrderStatus, discountTotal = 0) => ({
  id,
  storeId,
  status,
  discountTotal,
});

describe('summarizeCustomerOrders', () => {
  it('sin pedidos, todo en cero', () => {
    expect(summarizeCustomerOrders([])).toEqual({
      orderCount: 0,
      activeCount: 0,
      saved: 0,
      latestOrderId: null,
      repeat: [],
    });
  });

  it('cuenta los en curso, suma lo ahorrado y arma "Volver a pedir" por negocio', () => {
    const summary = summarizeCustomerOrders([
      order('o5', 's1', OrderStatus.PREPARING),
      order('o4', 's2', OrderStatus.DELIVERED, 500),
      order('o3', 's1', OrderStatus.DELIVERED),
      order('o2', 's1', OrderStatus.DELIVERED, 300),
      order('o1', 's3', OrderStatus.CANCELLED),
    ]);
    expect(summary).toMatchObject({ orderCount: 5, activeCount: 1, saved: 800, latestOrderId: 'o5' });
    // El último entregado de cada negocio, con las veces que se le pidió.
    expect(summary.repeat.map((r) => [r.order.id, r.deliveredCount])).toEqual([
      ['o4', 1],
      ['o3', 2],
    ]);
  });

  it('"Volver a pedir" se corta en los primeros negocios', () => {
    const many = Array.from({ length: REPEAT_STORES + 3 }, (_, i) => order(`o${i}`, `s${i}`, OrderStatus.DELIVERED));
    expect(summarizeCustomerOrders(many).repeat).toHaveLength(REPEAT_STORES);
  });
});
