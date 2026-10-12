import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { OrderStatus, PaymentMethodType } from '../src/generated/prisma/enums';
import { API, sessionFor, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CHASKI_OWNER = '910000000';
const STORE = 'st_chaski_dorado';
const QORI = 'st_pizzeria_qori';
const CITY = 'city_espinar';
const CUSTOMER_ID = 'usr_demo_customer';
const COURIER_USER = 'usr_courier_luis';
// Semana lejana para no cruzarse con los pedidos de otras suites.
const PAST_WEEK = '2025-03-05';
const PAST_MONDAY = '2025-03-03';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

describe('Comisión y liquidaciones (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let merchant: TestSession;
  let original: { rateBps: number | null; storeRateBps: number | null };
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const orderIds: string[] = [];
  const http = () => request(app.getHttpServer());

  const deliveredOrder = async (code: string, subtotal: number, commissionRateBps: number, deliveredAt: string) => {
    const order = await prisma.order.create({
      data: {
        code,
        customerId: CUSTOMER_ID,
        storeId: STORE,
        cityId: CITY,
        status: OrderStatus.DELIVERED,
        addressTitle: 'Casa',
        addressStreet: 'Jr. Túpac Amaru 214',
        deliveryLat: -14.7936,
        deliveryLng: -71.4128,
        storeName: 'Chaski Dorado',
        subtotal,
        deliveryFee: 350,
        total: subtotal + 350,
        currency: 'PEN',
        commissionRateBps,
        distanceMeters: 900,
        paymentMethod: PaymentMethodType.CASH,
        deliveredAt: new Date(deliveredAt),
        payment: {
          create: {
            method: PaymentMethodType.CASH,
            provider: 'on_delivery',
            amount: subtotal + 350,
            currency: 'PEN',
            collectedById: COURIER_USER,
            collectedMethod: PaymentMethodType.CASH,
            collectedAmount: subtotal + 350,
            collectedAt: new Date(deliveredAt),
          },
        },
      },
      select: { id: true },
    });
    orderIds.push(order.id);
  };

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await sessionFor(app, ADMIN);
    merchant = await sessionFor(app, CHASKI_OWNER);
    const [settings, store] = await Promise.all([
      prisma.platformSettings.findUnique({ where: { id: 1 } }),
      prisma.store.findUniqueOrThrow({ where: { id: STORE }, select: { commissionRateBps: true } }),
    ]);
    original = { rateBps: settings?.commissionRateBps ?? null, storeRateBps: store.commissionRateBps };
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });

    // Lima es UTC−5: martes 4 y jueves 6 de marzo de 2025 a mediodía.
    await deliveredOrder('#E2E-LIQ-1', 4000, 1000, '2025-03-04T17:00:00Z');
    await deliveredOrder('#E2E-LIQ-2', 2000, 500, '2025-03-06T17:00:00Z');
  });

  afterAll(async () => {
    await prisma.storeSettlement.deleteMany({ where: { storeId: { in: [STORE, QORI] } } });
    await prisma.order.deleteMany({ where: { id: { in: orderIds } } });
    if (original.rateBps !== null) {
      await prisma.platformSettings.update({ where: { id: 1 }, data: { commissionRateBps: original.rateBps } });
    }
    await prisma.store.update({ where: { id: STORE }, data: { commissionRateBps: original.storeRateBps } });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await app.close();
  });

  it('el admin cambia la comisión por defecto y queda quién la cambió', async () => {
    const res = await http().put(`${API}/admin/commission`).set(admin.auth).send({ rateBps: 1200 }).expect(200);
    expect(res.body).toMatchObject({ rateBps: 1200, updatedBy: { name: expect.any(String) } });
    await http().put(`${API}/admin/commission`).set(admin.auth).send({ rateBps: 20000 }).expect(400);
    await http().put(`${API}/admin/commission`).set(merchant.auth).send({ rateBps: 0 }).expect(403);
    const read = await http().get(`${API}/admin/commission`).set(admin.auth).expect(200);
    expect(read.body.rateBps).toBe(1200);
  });

  it('un negocio puede tener su propia comisión y volver a la de Apamuy', async () => {
    const own = await http()
      .put(`${API}/admin/stores/${STORE}/commission`)
      .set(admin.auth)
      .send({ rateBps: 800 })
      .expect(200);
    expect(own.body).toEqual({ storeId: STORE, rateBps: 800, defaultRateBps: 1200, effectiveRateBps: 800 });

    const reset = await http()
      .put(`${API}/admin/stores/${STORE}/commission`)
      .set(admin.auth)
      .send({ rateBps: null })
      .expect(200);
    expect(reset.body).toMatchObject({ rateBps: null, effectiveRateBps: 1200 });
    await http().get(`${API}/admin/stores/no-existe/commission`).set(admin.auth).expect(404);
  });

  it('cada pedido guarda la comisión con la que se creó', async () => {
    await prisma.store.update({ where: { id: STORE }, data: { commissionRateBps: 800 } });
    const customer = await signUp(app, '965000451');
    const { body } = await http()
      .post(`${API}/orders`)
      .set(customer.auth)
      .send({
        storeId: STORE,
        items: [{ productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1 }],
        address: {
          title: 'Casa',
          street: 'Jr. Túpac Amaru 214',
          reference: '',
          latitude: -14.7936,
          longitude: -71.4128,
        },
        payment: { type: 'CASH', changeFor: null },
        couponCode: null,
        scheduledFor: null,
        tip: { amount: 0, currency: 'PEN' },
        notes: '',
      })
      .expect(201);
    orderIds.push(body.id);
    const order = await prisma.order.findUniqueOrThrow({ where: { id: body.id }, select: { commissionRateBps: true } });
    expect(order.commissionRateBps).toBe(800);
  });

  it('la semana de cada negocio: vendido − comisión guardada en cada pedido = saldo', async () => {
    const res = await http().get(`${API}/admin/settlements`).query({ week: PAST_WEEK }).set(admin.auth).expect(200);
    expect(res.body.week).toEqual({
      start: PAST_MONDAY,
      end: '2025-03-09',
      previous: '2025-02-24',
      next: '2025-03-10',
      current: false,
    });
    const row = res.body.stores.find((s: { storeId: string }) => s.storeId === STORE);
    expect(row).toMatchObject({
      delivered: 2,
      sales: { amount: 6000, currency: 'PEN' },
      commission: { amount: 400 + 100 },
      collectedByStore: { amount: 0 },
      balance: { amount: 5500 },
      owedTo: 'STORE',
      status: 'PENDING',
      paid: null,
    });
    expect(res.body.totals).toMatchObject({ toStores: { amount: 5500 }, pendingCount: 1 });

    const detail = await http()
      .get(`${API}/admin/settlements/${STORE}`)
      .query({ week: PAST_WEEK })
      .set(admin.auth)
      .expect(200);
    expect(detail.body.orders.map((o: { rateBps: number }) => o.rateBps)).toEqual([1000, 500]);
  });

  it('el negocio ve solo sus liquidaciones', async () => {
    const res = await http()
      .get(`${API}/merchant/settlements`)
      .query({ week: PAST_WEEK })
      .set(merchant.auth)
      .expect(200);
    const ids = res.body.stores.map((s: { storeId: string }) => s.storeId);
    expect(ids).toContain(STORE);
    expect(ids).not.toContain(QORI);
    await http().get(`${API}/merchant/settlements/${QORI}`).query({ week: PAST_WEEK }).set(merchant.auth).expect(404);
    await http().get(`${API}/merchant/settlements`).query({ storeId: QORI }).set(merchant.auth).expect(404);
  });

  it('solo se paga una semana terminada, con pedidos y una sola vez', async () => {
    const today = await http()
      .post(`${API}/admin/settlements/${STORE}/pay`)
      .set(admin.auth)
      .send({
        week: new Date().toISOString().slice(0, 10),
      });
    expect(today.status).toBe(422);
    expect(today.body.code).toBe('SETTLEMENT_WEEK_OPEN');

    const empty = await http().post(`${API}/admin/settlements/${QORI}/pay`).set(admin.auth).send({ week: PAST_WEEK });
    expect(empty.status).toBe(422);
    expect(empty.body.code).toBe('SETTLEMENT_EMPTY');

    await http().post(`${API}/admin/settlements/${STORE}/pay`).set(merchant.auth).send({ week: PAST_WEEK }).expect(403);

    const paid = await http()
      .post(`${API}/admin/settlements/${STORE}/pay`)
      .set(admin.auth)
      .send({ week: PAST_WEEK })
      .expect(200);
    expect(paid.body).toMatchObject({
      status: 'PAID',
      paid: { by: { id: admin.user.id }, balance: { amount: 5500 } },
    });

    const again = await http().post(`${API}/admin/settlements/${STORE}/pay`).set(admin.auth).send({ week: PAST_WEEK });
    expect(again.status).toBe(409);
    expect(again.body.code).toBe('SETTLEMENT_ALREADY_PAID');

    const mine = await http().get(`${API}/merchant/settlements/${STORE}`).query({ week: PAST_WEEK }).set(merchant.auth);
    expect(mine.body).toMatchObject({ status: 'PAID', orders: expect.any(Array) });
  });
});
