import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { UnansweredOrdersJob } from '../src/modules/orders/status/unanswered-orders.job';
import { API, sessionFor, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));
const MINUTE = 60_000;

const body = () => ({
  storeId: STORE,
  items: [{ productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1 }],
  address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: '', latitude: -14.7936, longitude: -71.4128 },
  payment: { type: 'CASH', changeFor: null },
  couponCode: null,
  scheduledFor: null,
  tip: { amount: 0, currency: 'PEN' },
  notes: '',
});

type Column = { key: string; count: number; items: { id: string; alert: string | null; waitingMinutes: number }[] };

describe('Admin: pedidos en vivo (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let customer: TestSession;
  let admin: TestSession;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());
  const place = async () =>
    (await http().post(`${API}/orders`).set(customer.auth).send(body()).expect(201)).body as { id: string };
  const board = async () =>
    (await http().get(`${API}/admin/orders/board`).set(admin.auth).expect(200)).body as {
      columns: Column[];
      lateCount: number;
      today: { placed: number };
    };
  const ageOrder = (id: string, minutes: number) =>
    prisma.order.update({ where: { id }, data: { createdAt: new Date(Date.now() - minutes * MINUTE) } });

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });
    customer = await signUp(app, '965000301');
    // El celular del admin ya agotó sus códigos OTP en otras suites.
    admin = await sessionFor(app, ADMIN);
  });

  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await app.close();
  });

  it('solo el admin', async () => {
    await http().get(`${API}/admin/orders/board`).set(customer.auth).expect(403);
  });

  it('el pedido nuevo entra a "nuevos" y a los 3 minutos sin respuesta se marca como atrasado', async () => {
    const { id } = await place();
    let fresh = (await board()).columns.find((column) => column.key === 'new')!;
    expect(fresh.items.find((order) => order.id === id)).toMatchObject({ alert: null, waitingMinutes: 0 });

    await ageOrder(id, 4);
    const after = await board();
    fresh = after.columns.find((column) => column.key === 'new')!;
    expect(fresh.items.find((order) => order.id === id)).toMatchObject({ alert: 'late', waitingMinutes: 4 });
    expect(after.lateCount).toBeGreaterThanOrEqual(1);
    expect(after.today.placed).toBeGreaterThanOrEqual(1);
  });

  it('a los 8 minutos Apamuy lo cancela, sin autor y con el motivo para el cliente', async () => {
    const { id } = await place();
    await ageOrder(id, 9);

    await app.get(UnansweredOrdersJob).expire();

    const order = await prisma.order.findUniqueOrThrow({ where: { id } });
    expect(order).toMatchObject({
      status: 'CANCELLED',
      cancelledBy: null,
      cancelReason: 'el negocio no respondió a tiempo',
    });
    const detail = await http().get(`${API}/admin/orders/${id}`).set(admin.auth).expect(200);
    expect(detail.body).toMatchObject({ status: 'CANCELLED', cancelledBy: null });
  });

  it('el admin cancela con motivo y el historial del día lo encuentra por código', async () => {
    const { id } = await place();
    await http().post(`${API}/admin/orders/${id}/cancel`).set(admin.auth).send({ reason: 'x' }).expect(400);
    const cancelled = await http()
      .post(`${API}/admin/orders/${id}/cancel`)
      .set(admin.auth)
      .send({ reason: 'El cliente pidió cancelar por teléfono' })
      .expect(201);
    expect(cancelled.body).toMatchObject({ status: 'CANCELLED', cancelledBy: 'ADMIN' });

    const code = (await prisma.order.findUniqueOrThrow({ where: { id } })).code;
    const list = await http().get(`${API}/admin/orders`).query({ q: code }).set(admin.auth).expect(200);
    expect(list.body.items.map((order: { id: string }) => order.id)).toEqual([id]);
  });

  it('la caja del día agrupa por repartidor y por negocio', async () => {
    const res = await http().get(`${API}/admin/cash`).set(admin.auth).expect(200);
    expect(res.body).toMatchObject({
      date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      couriers: expect.any(Array),
      stores: expect.any(Array),
      collected: { total: { currency: 'PEN' } },
    });
    await http().get(`${API}/admin/cash`).query({ date: 'ayer' }).set(admin.auth).expect(400);
  });
});
