import { OrderStatus } from '../../generated/prisma/enums';
import { listScopeWhere } from './order-list-scope';

describe('listScopeWhere', () => {
  it('sin scope no filtra', () => {
    expect(listScopeWhere(undefined)).toEqual({});
  });

  it('active deja fuera entregados y cancelados', () => {
    expect(listScopeWhere('active')).toEqual({
      status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
    });
  });

  it('today usa el día de Lima', () => {
    // 01:00 en Lima del 25; en UTC ya es el 25 a las 06:00.
    expect(listScopeWhere('today', new Date('2026-09-25T06:00:00Z'))).toEqual({
      createdAt: { gte: new Date('2026-09-25T05:00:00Z'), lt: new Date('2026-09-26T05:00:00Z') },
    });
    // 23:30 en Lima del 24; en UTC ya es el 25.
    expect(listScopeWhere('today', new Date('2026-09-25T04:30:00Z'))).toEqual({
      createdAt: { gte: new Date('2026-09-24T05:00:00Z'), lt: new Date('2026-09-25T05:00:00Z') },
    });
  });
});
