import { Prisma } from '../../generated/prisma/client';
import { OrderStatus } from '../../generated/prisma/enums';
import { courierLocation } from './order-presenter';

const now = new Date('2026-10-08T15:00:00Z');
const courier = (secondsAgo: number) => ({
  currentLat: new Prisma.Decimal(-14.79),
  currentLng: new Prisma.Decimal(-71.41),
  lastLocationAt: new Date(now.getTime() - secondsAgo * 1000),
});

describe('courierLocation', () => {
  it('solo se ve mientras el pedido va en camino', () => {
    expect(courierLocation(OrderStatus.ON_THE_WAY, courier(10), now)).toEqual({
      lat: -14.79,
      lng: -71.41,
      at: '2026-10-08T14:59:50.000Z',
    });
    expect(courierLocation(OrderStatus.COURIER_ASSIGNED, courier(10), now)).toBeNull();
    expect(courierLocation(OrderStatus.DELIVERED, courier(10), now)).toBeNull();
  });

  it('una posición de más de 2 minutos ya no se muestra', () => {
    expect(courierLocation(OrderStatus.ON_THE_WAY, courier(119), now)).not.toBeNull();
    expect(courierLocation(OrderStatus.ON_THE_WAY, courier(121), now)).toBeNull();
    expect(courierLocation(OrderStatus.ON_THE_WAY, null, now)).toBeNull();
  });
});
