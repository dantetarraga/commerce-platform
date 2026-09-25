import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

// Usuarios del seed.
const CHASKI_OWNER = '910000000'; // dueño de st_chaski_dorado
const QORI_OWNER = '910000001'; // dueño de st_pizzeria_qori
const LUIS = '900000101'; // courier, "Moto roja"
const YENI = '900000102'; // courier

const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

const body = (couponCode: string | null = null) => ({
  storeId: STORE,
  items: [
    { productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1 },
    { productId: 'pr_pollo_cuarto', variantId: 'va_pc_pierna', optionValueIds: [], quantity: 1 },
  ],
  address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: '', latitude: -14.7936, longitude: -71.4128 },
  payment: { type: 'CASH', changeFor: null },
  couponCode,
  scheduledFor: null,
  tip: { amount: 0, currency: 'PEN' },
  notes: '',
});

describe('Operación del pedido (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let customer: TestSession;
  let merchant: TestSession;
  let otherMerchant: TestSession;
  let luis: TestSession;
  let yeni: TestSession;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());

  const place = async (session: TestSession, couponCode: string | null = null) =>
    (await http().post(`${API}/orders`).set(session.auth).send(body(couponCode)).expect(201)).body as {
      id: string;
      status: string;
    };
  const merchantStatus = (id: string, status: string, session = merchant) =>
    http().post(`${API}/merchant/orders/${id}/status`).set(session.auth).send({ status });
  const courierStatus = (id: string, status: string, session = luis) =>
    http().post(`${API}/courier/orders/${id}/status`).set(session.auth).send({ status });

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });
    await prisma.product.update({ where: { id: 'pr_pollo_medio' }, data: { stock: 10 } });

    customer = await signUp(app, '962000001');
    merchant = await logIn(app, CHASKI_OWNER);
    otherMerchant = await logIn(app, QORI_OWNER);
    luis = await logIn(app, LUIS);
    yeni = await logIn(app, YENI);
  });

  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await prisma.product.update({ where: { id: 'pr_pollo_medio' }, data: { stock: null } });
    await prisma.store.update({ where: { id: STORE }, data: { isAcceptingOrders: true } });
    await app.close();
  });

  it('de recibido a entregado: negocio y repartidor, cada uno en su paso', async () => {
    const order = await place(customer);
    const popularityBefore = (await prisma.store.findUniqueOrThrow({ where: { id: STORE } })).popularityScore;

    // El negocio ve el pedido con los datos del cliente; otro negocio no.
    const list = await http()
      .get(`${API}/merchant/orders`)
      .query({ status: 'RECEIVED' })
      .set(merchant.auth)
      .expect(200);
    const seen = list.body.items.find((o: { id: string }) => o.id === order.id);
    expect(seen).toMatchObject({
      customer: { name: 'Test User', phone: '962000001' },
      deliveryLocation: { lat: -14.7936, lng: -71.4128 },
    });
    await http().get(`${API}/merchant/orders/${order.id}`).set(otherMerchant.auth).expect(404);

    // Sin saltarse pasos, y el courier no puede tomarlo todavía.
    expect((await merchantStatus(order.id, 'READY').expect(409)).body.code).toBe('INVALID_STATUS_TRANSITION');
    await http().post(`${API}/courier/orders/${order.id}/accept`).set(luis.auth).expect(409);

    await merchantStatus(order.id, 'CONFIRMED').expect(200);
    await merchantStatus(order.id, 'PREPARING').expect(200);

    // Ya en preparación, el cliente no puede cancelar.
    const late = await http().post(`${API}/orders/${order.id}/cancel`).set(customer.auth).send({}).expect(409);
    expect(late.body.message).toContain('escríbenos');

    await merchantStatus(order.id, 'READY').expect(200);

    // Listo: aparece para los repartidores; lo toma uno solo.
    const available = await http().get(`${API}/courier/orders/available`).set(luis.auth).expect(200);
    expect(available.body.items.map((o: { id: string }) => o.id)).toContain(order.id);

    const accepted = await http().post(`${API}/courier/orders/${order.id}/accept`).set(luis.auth).expect(200);
    expect(accepted.body).toMatchObject({
      status: 'COURIER_ASSIGNED',
      courier: { name: 'Luis Quispe', vehicle: 'Moto roja', since: 2023 },
    });
    const taken = await http().post(`${API}/courier/orders/${order.id}/accept`).set(yeni.auth).expect(409);
    expect(taken.body.code).toBe('ORDER_ALREADY_TAKEN');

    // El negocio no entrega; otro courier no toca un pedido ajeno.
    await merchantStatus(order.id, 'ON_THE_WAY').expect(409);
    await courierStatus(order.id, 'ON_THE_WAY', yeni).expect(404);

    await courierStatus(order.id, 'ON_THE_WAY').expect(200);
    await courierStatus(order.id, 'DELIVERED').expect(200);

    // El cliente ve toda la línea de tiempo, como la pinta la app.
    const final = await http().get(`${API}/orders/${order.id}`).set(customer.auth).expect(200);
    expect(final.body.status).toBe('DELIVERED');
    expect(final.body.events.map((e: { status: string }) => e.status)).toEqual([
      'RECEIVED',
      'CONFIRMED',
      'PREPARING',
      'READY',
      'COURIER_ASSIGNED',
      'ON_THE_WAY',
      'DELIVERED',
    ]);

    const saved = await prisma.order.findUniqueOrThrow({ where: { id: order.id }, include: { payment: true } });
    expect(saved.deliveredAt).not.toBeNull();
    expect(saved.payment?.status).toBe('PAID');
    const store = await prisma.store.findUniqueOrThrow({ where: { id: STORE } });
    expect(store.popularityScore).toBe(popularityBefore + 1);

    // Entregado es final.
    expect((await courierStatus(order.id, 'DELIVERED').expect(409)).body.code).toBe('INVALID_STATUS_TRANSITION');
  });

  it('el cliente cancela a tiempo: vuelven el stock y el cupón', async () => {
    const buyer = await signUp(app, '962000002');
    const stockBefore = (await prisma.product.findUniqueOrThrow({ where: { id: 'pr_pollo_medio' } })).stock!;
    const coupon = await prisma.coupon.findUniqueOrThrow({ where: { code: 'ESPINAR' } });

    const order = await place(buyer, 'ESPINAR');
    expect((await prisma.product.findUniqueOrThrow({ where: { id: 'pr_pollo_medio' } })).stock).toBe(stockBefore - 1);

    const cancelled = await http()
      .post(`${API}/orders/${order.id}/cancel`)
      .set(buyer.auth)
      .send({ reason: 'Me equivoqué de dirección' })
      .expect(200);
    expect(cancelled.body.status).toBe('CANCELLED');

    expect((await prisma.product.findUniqueOrThrow({ where: { id: 'pr_pollo_medio' } })).stock).toBe(stockBefore);
    expect((await prisma.coupon.findUniqueOrThrow({ where: { id: coupon.id } })).usedCount).toBe(coupon.usedCount);
    const payment = await prisma.payment.findUniqueOrThrow({ where: { orderId: order.id } });
    expect(payment.status).toBe('CANCELLED');

    // El cupón vuelve a estar disponible para ese cliente.
    await http()
      .post(`${API}/coupons/validate`)
      .set(buyer.auth)
      .send({ code: 'ESPINAR', storeId: STORE, subtotal: { amount: 3000, currency: 'PEN' } })
      .expect(200);

    // Cancelado es final.
    await http().post(`${API}/orders/${order.id}/cancel`).set(buyer.auth).send({}).expect(409);
  });

  it('el negocio cancela con motivo, que ve en su vista', async () => {
    const order = await place(customer);
    await http().post(`${API}/merchant/orders/${order.id}/cancel`).set(merchant.auth).send({}).expect(400);
    const res = await http()
      .post(`${API}/merchant/orders/${order.id}/cancel`)
      .set(merchant.auth)
      .send({ reason: 'Se acabó el pollo' })
      .expect(200);
    expect(res.body).toMatchObject({ status: 'CANCELLED', cancelReason: 'Se acabó el pollo' });
  });

  it('pausar el negocio corta los pedidos nuevos; solo su dueño puede', async () => {
    await http()
      .patch(`${API}/merchant/stores/${STORE}`)
      .set(otherMerchant.auth)
      .send({ isAcceptingOrders: false })
      .expect(404);

    const paused = await http()
      .patch(`${API}/merchant/stores/${STORE}`)
      .set(merchant.auth)
      .send({ isAcceptingOrders: false })
      .expect(200);
    expect(paused.body).toEqual({ id: STORE, name: 'Pollería El Chaski Dorado', isAcceptingOrders: false });

    const closed = await http().post(`${API}/orders`).set(customer.auth).send(body()).expect(409);
    expect(closed.body.code).toBe('STORE_CLOSED');

    await http()
      .patch(`${API}/merchant/stores/${STORE}`)
      .set(merchant.auth)
      .send({ isAcceptingOrders: true })
      .expect(200);
  });

  it('cada rol solo entra a sus rutas', async () => {
    await http().get(`${API}/merchant/orders`).set(customer.auth).expect(403);
    await http().get(`${API}/courier/orders`).set(merchant.auth).expect(403);
    await http().post(`${API}/orders`).set(luis.auth).send(body()).expect(403);
  });
});
