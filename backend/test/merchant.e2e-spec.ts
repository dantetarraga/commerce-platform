import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { limaDate } from '../src/common/utils/lima-day';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

// Usuarios del seed.
const CHASKI_OWNER = '910000000'; // dueño de st_chaski_dorado
const QORI_OWNER = '910000001'; // dueño de st_pizzeria_qori
const ADMIN = '900000001';

const STORE = 'st_chaski_dorado';
const QORI = 'st_pizzeria_qori';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

const body = () => ({
  storeId: STORE,
  items: [
    { productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1, notes: 'Sin ají' },
    { productId: 'pr_pollo_cuarto', variantId: 'va_pc_pierna', optionValueIds: [], quantity: 1 },
  ],
  address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: '', latitude: -14.7936, longitude: -71.4128 },
  payment: { type: 'CASH', changeFor: null },
  couponCode: null,
  scheduledFor: null,
  tip: { amount: 0, currency: 'PEN' },
  notes: '',
});

type Summary = { date: string; deliveredCount: number; cancelledCount: number; activeCount: number; sales: Money };
type Money = { amount: number; currency: string };

describe('Chaski Socios: negocio (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let customer: TestSession;
  let merchant: TestSession;
  let otherMerchant: TestSession;
  let admin: TestSession;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());

  const place = async () =>
    (await http().post(`${API}/orders`).set(customer.auth).send(body()).expect(201)).body as {
      id: string;
      subtotal: Money;
    };
  const accept = (id: string, prepMinutes: unknown, session = merchant) =>
    http().post(`${API}/merchant/orders/${id}/accept`).set(session.auth).send({ prepMinutes });
  const summary = async (query: object = {}) =>
    (await http().get(`${API}/merchant/summary`).query(query).set(merchant.auth).expect(200)).body as Summary;
  const listIds = async (query: object) => {
    const res = await http().get(`${API}/merchant/orders`).query(query).set(merchant.auth).expect(200);
    return (res.body.items as { id: string }[]).map((o) => o.id);
  };

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });

    customer = await signUp(app, '965000001');
    merchant = await logIn(app, CHASKI_OWNER);
    otherMerchant = await logIn(app, QORI_OWNER);
    admin = await logIn(app, ADMIN);
  });

  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await prisma.product.update({ where: { id: 'pr_pollo_medio' }, data: { isAvailable: true } });
    await app.close();
  });

  it('mis negocios: solo los suyos, con horario y pausa por separado; el admin ve todos', async () => {
    const mine = await http().get(`${API}/merchant/stores`).set(merchant.auth).expect(200);
    expect(mine.body).toEqual([
      {
        id: STORE,
        name: 'Pollería El Chaski Dorado',
        logoUrl: expect.any(String),
        isAcceptingOrders: true,
        isOpenNow: true,
      },
    ]);

    const all = await http().get(`${API}/merchant/stores`).set(admin.auth).expect(200);
    const ids = (all.body as { id: string }[]).map((s) => s.id);
    expect(ids).toEqual(expect.arrayContaining([STORE, QORI]));
  });

  it('aceptar con tiempo: pasa a PREPARING en un paso, con dos filas de historial y un solo aviso', async () => {
    const order = await place();
    const before = await prisma.order.findUniqueOrThrow({ where: { id: order.id } });

    const invalid = await accept(order.id, 3).expect(400);
    expect(invalid.body.code).toBe('VALIDATION_ERROR');
    await accept(order.id, 91).expect(400);
    await accept(order.id, 20, otherMerchant).expect(404);

    const startedAt = Date.now();
    const res = await accept(order.id, 20).expect(200);
    expect(res.body).toMatchObject({
      id: order.id,
      status: 'PREPARING',
      lines: [{ name: '1/2 pollo a la brasa', notes: 'Sin ají' }, { notes: '' }],
      pickup: {
        address: expect.any(String),
        location: { lat: expect.any(Number), lng: expect.any(Number) },
      },
      distanceMeters: before.distanceMeters,
      collection: null,
      customer: { name: 'Test User', phone: '965000001' },
    });
    expect(res.body.pickup).toHaveProperty('phone');

    // Hora estimada = ahora + 20 min de preparación + viaje (redondeado a 5).
    const eta = new Date(res.body.estimatedArrival).getTime();
    expect(eta).toBeGreaterThanOrEqual(startedAt + 20 * 60_000);
    expect(eta).toBeLessThanOrEqual(Date.now() + 60 * 60_000);

    const history = await prisma.orderStatusHistory.findMany({
      where: { orderId: order.id },
      orderBy: { createdAt: 'asc' },
    });
    expect(history.map((h) => [h.fromStatus, h.toStatus])).toEqual([
      [null, 'RECEIVED'],
      ['RECEIVED', 'CONFIRMED'],
      ['CONFIRMED', 'PREPARING'],
    ]);

    const notices = await http().get(`${API}/notifications`).set(customer.auth).expect(200);
    const forOrder = (notices.body.items as { kind: string; orderId: string }[]).filter((n) => n.orderId === order.id);
    expect(forOrder.map((n) => n.kind)).toEqual(['PREPARING']);

    // Ya no está en RECEIVED: aceptar otra vez es un conflicto.
    expect((await accept(order.id, 20).expect(409)).body.code).toBe('INVALID_STATUS_TRANSITION');

    // Marcar listo con el endpoint de siempre.
    const ready = await http()
      .post(`${API}/merchant/orders/${order.id}/status`)
      .set(merchant.auth)
      .send({ status: 'READY' })
      .expect(200);
    expect(ready.body.status).toBe('READY');
  });

  it('rechazar es cancelar con motivo; los filtros active y today', async () => {
    const accepted = await place();
    await accept(accepted.id, 15).expect(200);
    const rejected = await place();
    const res = await http()
      .post(`${API}/merchant/orders/${rejected.id}/cancel`)
      .set(merchant.auth)
      .send({ reason: 'Sin stock de pollo' })
      .expect(200);
    expect(res.body).toMatchObject({ status: 'CANCELLED', cancelReason: 'Sin stock de pollo' });

    const active = await listIds({ scope: 'active' });
    expect(active).toContain(accepted.id);
    expect(active).not.toContain(rejected.id);

    const today = await listIds({ scope: 'today' });
    expect(today).toEqual(expect.arrayContaining([accepted.id, rejected.id]));

    // `scope` y `status` se combinan.
    const cancelledToday = await listIds({ scope: 'today', status: 'CANCELLED' });
    expect(cancelledToday).toContain(rejected.id);
    expect(cancelledToday).not.toContain(accepted.id);
    expect(await listIds({ scope: 'active', status: 'CANCELLED' })).toEqual([]);

    await http().get(`${API}/merchant/orders`).query({ scope: 'ayer' }).set(merchant.auth).expect(400);
  });

  it('productos: lista con precio y sección, marcar agotado; los de otro negocio dan 404', async () => {
    const list = await http().get(`${API}/merchant/stores/${STORE}/products`).set(merchant.auth).expect(200);
    const medio = (list.body as { id: string }[]).find((p) => p.id === 'pr_pollo_medio');
    expect(medio).toEqual({
      id: 'pr_pollo_medio',
      name: '1/2 pollo a la brasa',
      imageUrl: expect.any(String),
      price: { amount: 3500, currency: 'PEN' },
      section: 'Pollos a la brasa',
      isAvailable: true,
    });
    await http().get(`${API}/merchant/stores/${STORE}/products`).set(otherMerchant.auth).expect(404);
    await http().get(`${API}/merchant/stores/${STORE}/products`).set(admin.auth).expect(200);

    const off = await http()
      .patch(`${API}/merchant/products/pr_pollo_medio`)
      .set(merchant.auth)
      .send({ isAvailable: false })
      .expect(200);
    expect(off.body).toEqual({ id: 'pr_pollo_medio', isAvailable: false });
    expect((await prisma.product.findUniqueOrThrow({ where: { id: 'pr_pollo_medio' } })).isAvailable).toBe(false);

    // Agotado: el cliente ya no puede pedirlo.
    const blocked = await http().post(`${API}/orders`).set(customer.auth).send(body()).expect(409);
    expect(blocked.body.code).toBe('PRODUCT_UNAVAILABLE');

    await http()
      .patch(`${API}/merchant/products/pr_pollo_medio`)
      .set(otherMerchant.auth)
      .send({ isAvailable: true })
      .expect(404);
    await http().patch(`${API}/merchant/products/pr_pollo_medio`).set(merchant.auth).send({}).expect(400);
    await http()
      .patch(`${API}/merchant/products/pr_pollo_medio`)
      .set(merchant.auth)
      .send({ isAvailable: true })
      .expect(200);
  });

  it('resumen del día: cuenta los pedidos de hoy y suma lo vendido de los entregados', async () => {
    const before = await summary();
    expect(before.date).toBe(limaDate(new Date()));
    const otherSummary = async () =>
      (await http().get(`${API}/merchant/summary`).set(otherMerchant.auth).expect(200)).body as Summary;
    const otherBefore = await otherSummary();

    const delivered = await place();
    await prisma.order.update({ where: { id: delivered.id }, data: { status: 'DELIVERED', deliveredAt: new Date() } });
    const cancelled = await place();
    await http()
      .post(`${API}/merchant/orders/${cancelled.id}/cancel`)
      .set(merchant.auth)
      .send({ reason: 'Cerramos temprano' })
      .expect(200);
    await place(); // queda activo

    const after = await summary({ date: before.date });
    expect(after).toEqual({
      date: before.date,
      deliveredCount: before.deliveredCount + 1,
      cancelledCount: before.cancelledCount + 1,
      activeCount: before.activeCount + 1,
      sales: { amount: before.sales.amount + delivered.subtotal.amount, currency: 'PEN' },
    });

    // Otro día: nada. Fecha inválida: 400.
    expect(await summary({ date: '2020-01-01' })).toEqual({
      date: '2020-01-01',
      deliveredCount: 0,
      cancelledCount: 0,
      activeCount: 0,
      sales: { amount: 0, currency: 'PEN' },
    });
    await http().get(`${API}/merchant/summary`).query({ date: '2026-13-40' }).set(merchant.auth).expect(400);

    // El otro negocio no ve estos pedidos.
    expect(await otherSummary()).toEqual(otherBefore);
  });
});
