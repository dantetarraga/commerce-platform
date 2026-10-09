import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { PushSender } from '../src/modules/push/push-sender';
import { API, sessionFor, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

const OWNER = '910000000'; // dueño de st_chaski_dorado
const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));
const token = (name: string) => `fcm-token-${name}-${'x'.repeat(20)}`;

describe('Push (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let owner: TestSession;
  let customer: TestSession;
  let send: jest.SpyInstance;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    send = jest.spyOn(app.get(PushSender), 'send');
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });
    owner = await sessionFor(app, OWNER);
    customer = await signUp(app, '965000501');
  });

  afterAll(async () => {
    await prisma.device.deleteMany({ where: { pushToken: { in: [token('owner'), token('customer')] } } });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await app.close();
  });

  it('registra el teléfono y valida la app que lo envía', async () => {
    await http()
      .put(`${API}/users/me/devices`)
      .set(owner.auth)
      .send({ pushToken: token('owner'), platform: 'android', app: 'partner' })
      .expect(204);
    await http()
      .put(`${API}/users/me/devices`)
      .set(customer.auth)
      .send({ pushToken: token('customer'), platform: 'android', app: 'customer' })
      .expect(204);
    await http()
      .put(`${API}/users/me/devices`)
      .set(customer.auth)
      .send({ pushToken: token('otro'), platform: 'android', app: 'web' })
      .expect(400);
  });

  it('un pedido nuevo hace sonar la alarma en el teléfono del dueño', async () => {
    send.mockClear();
    await http()
      .post(`${API}/orders`)
      .set(customer.auth)
      .send({
        storeId: STORE,
        items: [{ productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1 }],
        address: { title: 'Casa', street: 'Jr. Lima 120', reference: '', latitude: -14.7936, longitude: -71.4128 },
        payment: { type: 'CASH', changeFor: null },
        couponCode: null,
        scheduledFor: null,
        tip: { amount: 0, currency: 'PEN' },
        notes: '',
      })
      .expect(201);

    await new Promise((resolve) => setTimeout(resolve, 200)); // el listener corre tras el commit
    const alarm = send.mock.calls.find(([, message]) => message.channel === 'order_alarm');
    expect(alarm?.[0]).toEqual([token('owner')]);
    expect(alarm?.[1]).toMatchObject({ data: { type: 'NEW_ORDER' }, ttlSeconds: 480 });
  });

  it('al cerrar sesión el teléfono deja de recibir avisos', async () => {
    await http()
      .delete(`${API}/users/me/devices`)
      .set(owner.auth)
      .send({ pushToken: token('owner') })
      .expect(204);
    expect(await prisma.device.count({ where: { pushToken: token('owner') } })).toBe(0);
  });
});
