import type { INestApplication } from '@nestjs/common';
import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { io, type Socket } from 'socket.io-client';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, sessionFor, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

// Usuarios del seed.
const CHASKI_OWNER = '910000000'; // dueño de st_chaski_dorado
const LUIS = '900000101'; // courier
const YENI = '900000102'; // courier

const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));
const ORDER = {
  storeId: STORE,
  items: [{ productId: 'pr_pollo_medio', variantId: null, optionValueIds: [], quantity: 1 }],
  address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: '', latitude: -14.7936, longitude: -71.4128 },
  payment: { type: 'CASH', changeFor: null },
  couponCode: null,
  scheduledFor: null,
  tip: { amount: 0, currency: 'PEN' },
  notes: '',
};

/** Espera el próximo `event` que cumpla `match` (falla a los 3 s). */
function next<T>(socket: Socket, event: string, match: (payload: T) => boolean = () => true): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off(event, handler);
      reject(new Error(`No llegó ${event}`));
    }, 3000);
    const handler = (payload: T) => {
      if (!match(payload)) return;
      clearTimeout(timer);
      socket.off(event, handler);
      resolve(payload);
    };
    socket.on(event, handler);
  });
}

describe('Tiempo real (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let url: string;
  let customer: TestSession;
  let stranger: TestSession;
  let merchant: TestSession;
  let luis: TestSession;
  let yeni: TestSession;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  let originalPopularity: number;
  const sockets: Socket[] = [];
  const http = () => request(app.getHttpServer());

  const connect = async (session?: TestSession) => {
    const socket = io(`${url}/ws`, {
      auth: session ? { token: session.accessToken } : {},
      transports: ['websocket'],
      reconnection: false,
    });
    sockets.push(socket);
    if (session) await next(socket, 'connect');
    return socket;
  };
  const subscribe = (socket: Socket, orderId: string) =>
    socket.emitWithAck('order.subscribe', { orderId }) as Promise<{ ok: boolean; code?: string }>;

  beforeAll(async () => {
    app = await createTestApp();
    await app.listen(0);
    const server = app.getHttpServer() as unknown as Server;
    url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    // Entregar suma popularidad; se restaura para no cambiar el orden que prueba catalog.
    originalPopularity = (await prisma.store.findUniqueOrThrow({ where: { id: STORE } })).popularityScore;
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });

    customer = await signUp(app, '964000001');
    stranger = await signUp(app, '964000002');
    merchant = await sessionFor(app, CHASKI_OWNER);
    luis = await sessionFor(app, LUIS);
    yeni = await sessionFor(app, YENI);
    await http().patch(`${API}/courier/me/status`).set(luis.auth).send({ status: 'AVAILABLE' }).expect(200);
  });

  afterAll(async () => {
    sockets.forEach((s) => s.disconnect());
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await prisma.store.update({ where: { id: STORE }, data: { popularityScore: originalPopularity } });
    await prisma.courier.updateMany({ data: { status: 'OFFLINE', lastLocationAt: null } });
    await app.close();
  });

  it('sin token válido no deja conectar', async () => {
    const error = await next<Error>(await connect(), 'connect_error');
    expect(error.message).toBe('UNAUTHORIZED');
    const forged = io(`${url}/ws`, { auth: { token: 'no-es-un-jwt' }, transports: ['websocket'], reconnection: false });
    sockets.push(forged);
    expect((await next<Error>(forged, 'connect_error')).message).toBe('UNAUTHORIZED');
  });

  it('avisa a negocio, repartidores y cliente en cada paso, con la moto en vivo', async () => {
    const shop = await connect(merchant);
    const rider = await connect(luis);
    const buyer = await connect(customer);
    const other = await connect(stranger);

    // El negocio recibe el pedido nuevo sin consultar.
    const placed = next<{ orderId: string; status: string }>(shop, 'store.orders.changed');
    const order = (await http().post(`${API}/orders`).set(customer.auth).send(ORDER).expect(201)).body as {
      id: string;
    };
    expect(await placed).toEqual({ orderId: order.id, status: 'RECEIVED' });

    expect(await subscribe(buyer, order.id)).toEqual({ ok: true });
    expect(await subscribe(other, order.id)).toEqual({ ok: false, code: 'NOT_FOUND' });

    const advance = (status: string) =>
      http().post(`${API}/merchant/orders/${order.id}/status`).set(merchant.auth).send({ status }).expect(200);
    const confirmed = next(buyer, 'order.updated');
    await advance('CONFIRMED');
    expect(await confirmed).toEqual({ orderId: order.id, status: 'CONFIRMED' });
    await advance('PREPARING');

    // Listo: los repartidores conectados de la ciudad se enteran.
    const ready = next(rider, 'courier.orders.changed', (p: { status: string }) => p.status === 'READY');
    await advance('READY');
    await ready;

    await http().post(`${API}/courier/orders/${order.id}/accept`).set(luis.auth).expect(200);
    const onTheWay = next(buyer, 'order.updated', (p: { status: string }) => p.status === 'ON_THE_WAY');
    await http()
      .post(`${API}/courier/orders/${order.id}/status`)
      .set(luis.auth)
      .send({ status: 'ON_THE_WAY' })
      .expect(200);
    await onTheWay;

    const moved = next(buyer, 'courier.location');
    await http().post(`${API}/courier/me/location`).set(luis.auth).send({ lat: -14.79, lng: -71.41 }).expect(204);
    expect(await moved).toMatchObject({ orderId: order.id, lat: -14.79, lng: -71.41 });
    // Un segundo envío inmediato se ignora (se guarda uno cada 2 s).
    await http().post(`${API}/courier/me/location`).set(luis.auth).send({ lat: 0, lng: 0 }).expect(204);

    const tracking = await http().get(`${API}/orders/${order.id}`).set(customer.auth).expect(200);
    expect(tracking.body.courier.location).toMatchObject({ lat: -14.79, lng: -71.41 });
    expect(tracking.body.store.location).toEqual({ lat: expect.any(Number), lng: expect.any(Number) });
    expect(tracking.body.address.location).toEqual({ lat: -14.7936, lng: -71.4128 });

    // Entregado: la posición deja de mostrarse.
    const collection = { collectedMethod: 'CASH', collectedAmount: { amount: 5000, currency: 'PEN' } };
    await http()
      .post(`${API}/courier/orders/${order.id}/status`)
      .set(luis.auth)
      .send({ status: 'DELIVERED', ...collection })
      .expect(200);
    const delivered = await http().get(`${API}/orders/${order.id}`).set(customer.auth).expect(200);
    expect(delivered.body.courier.location).toBeNull();
  });

  it('desconectado no comparte ubicación y valida las coordenadas', async () => {
    const offline = await http().post(`${API}/courier/me/location`).set(yeni.auth).send({ lat: -14.79, lng: -71.41 });
    expect(offline.status).toBe(409);
    expect(offline.body.code).toBe('COURIER_NOT_AVAILABLE');
    await http().post(`${API}/courier/me/location`).set(luis.auth).send({ lat: 200, lng: 0 }).expect(400);
    await http().post(`${API}/courier/me/location`).set(customer.auth).send({ lat: 0, lng: 0 }).expect(403);
  });
});
