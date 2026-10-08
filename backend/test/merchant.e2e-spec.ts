import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { DEFAULT_TIMEZONE, zonedTime } from '../src/common/time';
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

type Summary = {
  date: string;
  deliveredCount: number;
  cancelledCount: number;
  activeCount: number;
  sales: Money;
  averageTicket: Money | null;
  averagePrepMinutes: number | null;
  peakHour: number | null;
  salesByHour: { hour: number; sales: Money; orders: number }[];
  payments: { method: string; sales: Money; orders: number; share: number }[];
  topProducts: { productId: string | null; name: string; quantity: number; sales: Money }[];
};
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
    type Catalog = {
      counts: { all: number; available: number; soldOut: number };
      sections: { name: string; items: { id: string; name: string; isAvailable: boolean }[] }[];
    };
    const catalog = async (query: object = {}) =>
      (await http().get(`${API}/merchant/stores/${STORE}/products`).query(query).set(merchant.auth).expect(200))
        .body as Catalog;
    const ids = (c: Catalog) => c.sections.flatMap((s) => s.items.map((p) => p.id));

    const all = await catalog();
    expect(all.counts.all).toBe(all.counts.available + all.counts.soldOut);
    expect(ids(all)).toHaveLength(all.counts.all);
    // Agrupado por sección y en el orden del menú: cada sección aparece una vez.
    expect(new Set(all.sections.map((s) => s.name)).size).toBe(all.sections.length);
    const medio = all.sections.flatMap((s) => s.items).find((p) => p.id === 'pr_pollo_medio');
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

    // Las pestañas y la búsqueda las resuelve el backend.
    const soldOut = await catalog({ status: 'sold_out' });
    expect(ids(soldOut)).toContain('pr_pollo_medio');
    expect(soldOut.counts).toEqual({
      all: all.counts.all,
      available: all.counts.available - 1,
      soldOut: all.counts.soldOut + 1,
    });
    expect(ids(await catalog({ status: 'available' }))).not.toContain('pr_pollo_medio');
    // Sin tildes ni mayúsculas.
    expect(ids(await catalog({ q: 'POLLO A LA BRASA' }))).toContain('pr_pollo_medio');
    expect(ids(await catalog({ q: 'ninguno-asi' }))).toEqual([]);
    await http()
      .get(`${API}/merchant/stores/${STORE}/products`)
      .query({ status: 'todos' })
      .set(merchant.auth)
      .expect(400);
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

  it('tablero: el backend reparte los pedidos en curso en tres columnas y las cuenta', async () => {
    type Board = { columns: { key: string; count: number; items: { id: string; status: string }[] }[] };
    const board = async (session = merchant) =>
      (await http().get(`${API}/merchant/board`).set(session.auth).expect(200)).body as Board;
    const column = (b: Board, key: string) => b.columns.find((c) => c.key === key)!;

    const order = await place();
    let now = await board();
    expect(now.columns.map((c) => c.key)).toEqual(['fresh', 'cooking', 'ready']);
    expect(column(now, 'fresh').items.map((o) => o.id)).toContain(order.id);
    for (const c of now.columns) expect(c.count).toBe(c.items.length);

    await accept(order.id, 20).expect(200);
    now = await board();
    expect(column(now, 'fresh').items.map((o) => o.id)).not.toContain(order.id);
    expect(column(now, 'cooking').items.find((o) => o.id === order.id)?.status).toBe('PREPARING');

    // Otro negocio no ve este pedido en su tablero.
    const other = await board(otherMerchant);
    expect(other.columns.flatMap((c) => c.items.map((o) => o.id))).not.toContain(order.id);
  });

  it('resumen del día: cuenta los pedidos de hoy y suma lo vendido de los entregados', async () => {
    const before = await summary();
    expect(before.date).toBe(zonedTime.localDate(new Date(), DEFAULT_TIMEZONE));
    const otherSummary = async () =>
      (await http().get(`${API}/merchant/summary`).set(otherMerchant.auth).expect(200)).body as Summary;
    const otherBefore = await otherSummary();

    const delivered = await place();
    const now = Date.now();
    await prisma.order.update({
      where: { id: delivered.id },
      data: {
        status: 'DELIVERED',
        acceptedAt: new Date(now - 12 * 60_000),
        readyAt: new Date(now - 60_000),
        deliveredAt: new Date(now),
      },
    });
    const cancelled = await place();
    await http()
      .post(`${API}/merchant/orders/${cancelled.id}/cancel`)
      .set(merchant.auth)
      .send({ reason: 'Cerramos temprano' })
      .expect(200);
    await place(); // queda activo

    const after = await summary({ date: before.date });
    expect(after).toMatchObject({
      date: before.date,
      deliveredCount: before.deliveredCount + 1,
      cancelledCount: before.cancelledCount + 1,
      activeCount: before.activeCount + 1,
      sales: { amount: before.sales.amount + delivered.subtotal.amount, currency: 'PEN' },
    });
    // Las gráficas salen del backend: horas, pagos y productos de los entregados.
    expect(after.averagePrepMinutes).toEqual(expect.any(Number));
    expect(after.averageTicket?.amount).toBe(Math.round(after.sales.amount / after.deliveredCount));
    expect(after.salesByHour.reduce((sum, h) => sum + h.sales.amount, 0)).toBe(after.sales.amount);
    expect(after.salesByHour.map((h) => h.hour)).toContain(after.peakHour);
    expect(after.payments.map((p) => p.method)).toEqual(['CASH', 'YAPE', 'PLIN']);
    expect(after.payments.reduce((sum, p) => sum + p.share, 0)).toBe(100);
    expect(after.topProducts.map((p) => p.productId)).toEqual(
      expect.arrayContaining(['pr_pollo_medio', 'pr_pollo_cuarto']),
    );

    // Aceptar y marcar listo guarda las horas que usa el tiempo de preparación.
    const cooked = await place();
    await accept(cooked.id, 15).expect(200);
    await http()
      .post(`${API}/merchant/orders/${cooked.id}/status`)
      .set(merchant.auth)
      .send({ status: 'READY' })
      .expect(200);
    const stamped = await prisma.order.findUniqueOrThrow({ where: { id: cooked.id } });
    expect(stamped.acceptedAt).toEqual(expect.any(Date));
    expect(stamped.readyAt!.getTime()).toBeGreaterThanOrEqual(stamped.acceptedAt!.getTime());

    // Otro día: nada. Fecha inválida: 400.
    expect(await summary({ date: '2020-01-01' })).toEqual({
      date: '2020-01-01',
      deliveredCount: 0,
      cancelledCount: 0,
      activeCount: 0,
      sales: { amount: 0, currency: 'PEN' },
      averageTicket: null,
      averagePrepMinutes: null,
      peakHour: null,
      salesByHour: [],
      payments: ['CASH', 'YAPE', 'PLIN'].map((method) => ({
        method,
        sales: { amount: 0, currency: 'PEN' },
        orders: 0,
        share: 0,
      })),
      topProducts: [],
    });
    await http().get(`${API}/merchant/summary`).query({ date: '2026-13-40' }).set(merchant.auth).expect(400);

    // El otro negocio no ve estos pedidos.
    expect(await otherSummary()).toEqual(otherBefore);
  });
});
