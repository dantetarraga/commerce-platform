import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

// Usuarios del seed.
const CHASKI_OWNER = '910000000'; // dueño de st_chaski_dorado
const ADMIN = '900000001';
const LUIS = '900000101'; // courier, "Moto roja"
const YENI = '900000102'; // courier

const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

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

type Money = { amount: number; currency: string };
type CourierSummary = {
  date: string;
  deliveredCount: number;
  collected: { total: Money; CASH: Money; YAPE: Money; PLIN: Money };
};

describe('Chaski Socios: repartidor (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let customer: TestSession;
  let merchant: TestSession;
  let admin: TestSession;
  let luis: TestSession;
  let yeni: TestSession;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  let originalPopularity: number;
  const http = () => request(app.getHttpServer());

  /** Un pedido nuevo, aceptado y listo en el negocio: disponible para repartidores. */
  const readyOrder = async () => {
    const order = (await http().post(`${API}/orders`).set(customer.auth).send(body()).expect(201)).body as {
      id: string;
      total: Money;
    };
    await http()
      .post(`${API}/merchant/orders/${order.id}/accept`)
      .set(merchant.auth)
      .send({ prepMinutes: 10 })
      .expect(200);
    await http()
      .post(`${API}/merchant/orders/${order.id}/status`)
      .set(merchant.auth)
      .send({ status: 'READY' })
      .expect(200);
    return order;
  };
  const me = async (session: TestSession) =>
    (await http().get(`${API}/courier/me`).set(session.auth).expect(200)).body as {
      status: string;
      activeOrderId: string | null;
    };
  const setStatus = (session: TestSession, status: string) =>
    http().patch(`${API}/courier/me/status`).set(session.auth).send({ status });
  const acceptOrder = (session: TestSession, id: string) =>
    http().post(`${API}/courier/orders/${id}/accept`).set(session.auth);
  const courierStatus = (session: TestSession, id: string, payload: object) =>
    http().post(`${API}/courier/orders/${id}/status`).set(session.auth).send(payload);
  const availableIds = async (session: TestSession) => {
    const res = await http().get(`${API}/courier/orders/available`).set(session.auth).expect(200);
    return (res.body.items as { id: string }[]).map((o) => o.id);
  };
  const summary = async (session: TestSession) =>
    (await http().get(`${API}/courier/me/summary`).set(session.auth).expect(200)).body as CourierSummary;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });
    await prisma.courier.updateMany({ data: { status: 'OFFLINE' } });
    // Entregar suma popularidad; se restaura para no mover el orden del catálogo.
    originalPopularity = (await prisma.store.findUniqueOrThrow({ where: { id: STORE } })).popularityScore;

    customer = await signUp(app, '966000001');
    merchant = await logIn(app, CHASKI_OWNER);
    admin = await logIn(app, ADMIN);
    luis = await logIn(app, LUIS);
    yeni = await logIn(app, YENI);
  });

  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await prisma.courier.updateMany({ data: { status: 'OFFLINE' } });
    await prisma.store.update({ where: { id: STORE }, data: { popularityScore: originalPopularity } });
    await app.close();
  });

  it('perfil del repartidor', async () => {
    const res = await http().get(`${API}/courier/me`).set(luis.auth).expect(200);
    expect(res.body).toEqual({
      id: expect.any(String),
      name: 'Luis Quispe',
      phone: LUIS,
      vehicleLabel: 'Moto roja',
      status: 'OFFLINE',
      activeOrderId: null,
    });
    await http().get(`${API}/courier/me`).set(merchant.auth).expect(403);
  });

  it('desconectado: no ve disponibles ni puede tomar pedidos', async () => {
    const order = await readyOrder();
    expect(await availableIds(luis)).toEqual([]);
    const res = await acceptOrder(luis, order.id).expect(409);
    expect(res.body.code).toBe('COURIER_NOT_AVAILABLE');

    await setStatus(luis, 'BUSY').expect(400);
    const connected = await setStatus(luis, 'AVAILABLE').expect(200);
    expect(connected.body).toMatchObject({ status: 'AVAILABLE', activeOrderId: null });
    expect(await availableIds(luis)).toContain(order.id);

    // Se puede desconectar sin pedido en curso.
    expect((await setStatus(luis, 'OFFLINE').expect(200)).body.status).toBe('OFFLINE');
  });

  it('dos repartidores aceptan a la vez: uno solo se lo lleva; el ganador queda BUSY y vuelve al entregar', async () => {
    await setStatus(luis, 'AVAILABLE').expect(200);
    await setStatus(yeni, 'AVAILABLE').expect(200);
    const order = await readyOrder();

    const [a, b] = await Promise.all([acceptOrder(luis, order.id), acceptOrder(yeni, order.id)]);
    expect([a.status, b.status].sort()).toEqual([200, 409]);
    const [winner, loser] = a.status === 200 ? [luis, yeni] : [yeni, luis];
    const lost = a.status === 200 ? b : a;
    expect(lost.body.code).toBe('ORDER_ALREADY_TAKEN');

    expect(await me(winner)).toMatchObject({ status: 'BUSY', activeOrderId: order.id });
    expect(await me(loser)).toMatchObject({ status: 'AVAILABLE', activeOrderId: null });

    // Con un pedido en curso: no ve ni toma otros, y no puede desconectarse.
    const another = await readyOrder();
    expect(await availableIds(winner)).toEqual([]);
    expect((await acceptOrder(winner, another.id).expect(409)).body.code).toBe('COURIER_NOT_AVAILABLE');
    expect((await setStatus(winner, 'OFFLINE').expect(409)).body.code).toBe('COURIER_HAS_ACTIVE_ORDER');
    expect((await setStatus(winner, 'AVAILABLE').expect(200)).body.status).toBe('BUSY');

    // Filtro de sus pedidos.
    const active = await http().get(`${API}/courier/orders`).query({ scope: 'active' }).set(winner.auth).expect(200);
    expect(active.body.items.map((o: { id: string }) => o.id)).toEqual([order.id]);

    const before = await summary(winner);

    await courierStatus(winner, order.id, { status: 'ON_THE_WAY' }).expect(200);

    // Entregar exige decir cómo pagó el cliente y cuánto se cobró.
    const missing = await courierStatus(winner, order.id, { status: 'DELIVERED' }).expect(422);
    expect(missing.body.code).toBe('COLLECTION_REQUIRED');
    await courierStatus(winner, order.id, {
      status: 'DELIVERED',
      collectedMethod: 'CARD',
      collectedAmount: { amount: 100, currency: 'PEN' },
    }).expect(400);

    // Un monto distinto al total se acepta y queda registrado.
    const collected = order.total.amount - 50;
    const delivered = await courierStatus(winner, order.id, {
      status: 'DELIVERED',
      collectedMethod: 'YAPE',
      collectedAmount: { amount: collected, currency: 'PEN' },
    }).expect(200);
    expect(delivered.body).toMatchObject({
      status: 'DELIVERED',
      collection: { method: 'YAPE', amount: { amount: collected, currency: 'PEN' }, collectedAt: expect.any(String) },
    });
    const payment = await prisma.payment.findUniqueOrThrow({ where: { orderId: order.id } });
    expect(payment).toMatchObject({
      status: 'PAID',
      amount: order.total.amount,
      collectedById: winner.user.id,
      collectedMethod: 'YAPE',
      collectedAmount: collected,
    });

    expect(await me(winner)).toMatchObject({ status: 'AVAILABLE', activeOrderId: null });

    const after = await summary(winner);
    expect(after.deliveredCount).toBe(before.deliveredCount + 1);
    expect(after.collected.YAPE.amount).toBe(before.collected.YAPE.amount + collected);
    expect(after.collected.total.amount).toBe(before.collected.total.amount + collected);
    expect(after.collected.CASH).toEqual(before.collected.CASH);

    const activeNow = await http().get(`${API}/courier/orders`).query({ scope: 'active' }).set(winner.auth).expect(200);
    expect(activeNow.body.items).toEqual([]);
    const today = await http().get(`${API}/courier/orders`).query({ scope: 'today' }).set(winner.auth).expect(200);
    expect(today.body.items.map((o: { id: string }) => o.id)).toContain(order.id);

    // Libre otra vez, toma el siguiente.
    await acceptOrder(winner, another.id).expect(200);
    await courierStatus(winner, another.id, { status: 'ON_THE_WAY' }).expect(200);
    await courierStatus(winner, another.id, {
      status: 'DELIVERED',
      collectedMethod: 'CASH',
      collectedAmount: { amount: another.total.amount, currency: 'PEN' },
    }).expect(200);
  });

  it('si se cancela su pedido, el repartidor vuelve a estar disponible', async () => {
    await setStatus(luis, 'AVAILABLE').expect(200);
    const order = await readyOrder();
    await acceptOrder(luis, order.id).expect(200);
    expect((await me(luis)).status).toBe('BUSY');

    await http()
      .post(`${API}/merchant/orders/${order.id}/cancel`)
      .set(admin.auth)
      .send({ reason: 'El cliente no contesta' })
      .expect(200);
    expect(await me(luis)).toMatchObject({ status: 'AVAILABLE', activeOrderId: null });
  });

  it('resumen de otro día: vacío', async () => {
    const res = await http().get(`${API}/courier/me/summary`).query({ date: '2020-01-01' }).set(luis.auth).expect(200);
    const zero = { amount: 0, currency: 'PEN' };
    expect(res.body).toEqual({
      date: '2020-01-01',
      deliveredCount: 0,
      collected: { total: zero, CASH: zero, YAPE: zero, PLIN: zero },
    });
  });
});
