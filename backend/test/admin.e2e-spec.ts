import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CHASKI_OWNER = '910000000';
const ORDER_STORE = 'st_chaski_dorado';
const TRANSFER_STORE = 'st_quesos_kana'; // ningún otro e2e lo usa
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

const NEW_MERCHANT = '911000001';
const NEW_COURIER = '911000002';

type Partner = {
  id: string;
  phone: string;
  roles: string[];
  stores: { id: string; name: string; isAcceptingOrders: boolean }[];
  courier: { vehicleLabel: string; status: string } | null;
};

describe('Admin: alta y suspensión de socios (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let cityId: string;
  let originalOwner: string;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());

  const courierBody = (phone: string, vehicleLabel = 'Moto verde') => ({
    phone,
    firstName: 'Rosa',
    lastName: 'Huamán',
    cityId,
    vehicleType: 'MOTO',
    vehicleLabel,
  });
  const suspend = (id: string, body: object = {}) =>
    http().post(`${API}/admin/users/${id}/suspend-partner`).set(admin.auth).send(body);

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await logIn(app, ADMIN);
    cityId = (await prisma.city.findFirstOrThrow()).id;
    originalOwner = (await prisma.store.findUniqueOrThrow({ where: { id: TRANSFER_STORE } })).ownerId;
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: ORDER_STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
  });

  afterAll(async () => {
    await prisma.store.update({
      where: { id: TRANSFER_STORE },
      data: { ownerId: originalOwner, isAcceptingOrders: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: ORDER_STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await app.close();
  });

  it('solo el admin entra', async () => {
    const merchant = await logIn(app, CHASKI_OWNER);
    await http().get(`${API}/admin/users`).query({ phone: ADMIN }).set(merchant.auth).expect(403);
    await http().get(`${API}/admin/users`).query({ phone: ADMIN }).expect(401);
  });

  it('busca una cuenta por celular', async () => {
    const res = await http().get(`${API}/admin/users`).query({ phone: CHASKI_OWNER }).set(admin.auth).expect(200);
    expect(res.body.roles).toContain('MERCHANT');
    expect(res.body.stores.map((s: { id: string }) => s.id)).toContain(ORDER_STORE);
    await http().get(`${API}/admin/users`).query({ phone: '999999999' }).set(admin.auth).expect(404);
    await http().get(`${API}/admin/users`).query({ phone: '123' }).set(admin.auth).expect(400);
  });

  it('da de alta un negocio nuevo con su local y puede entrar a Socios', async () => {
    const res = await http()
      .post(`${API}/admin/merchants`)
      .set(admin.auth)
      .send({ phone: NEW_MERCHANT, firstName: 'Kana', lastName: 'Ccori', storeIds: [TRANSFER_STORE] })
      .expect(201);
    const user = res.body.user as Partner;
    expect(res.body.created).toBe(true);
    expect(user.roles.sort()).toEqual(['CUSTOMER', 'MERCHANT']);
    expect(user.stores.map((s) => s.id)).toEqual([TRANSFER_STORE]);

    const session = await logIn(app, NEW_MERCHANT);
    const stores = await http().get(`${API}/merchant/stores`).set(session.auth).expect(200);
    expect(stores.body.map((s: { id: string }) => s.id)).toEqual([TRANSFER_STORE]);

    // Repetir el alta no duplica nada.
    const again = await http()
      .post(`${API}/admin/merchants`)
      .set(admin.auth)
      .send({ phone: NEW_MERCHANT, firstName: 'Otro', lastName: 'Nombre' })
      .expect(201);
    expect(again.body.created).toBe(false);
    expect(again.body.user.roles.sort()).toEqual(['CUSTOMER', 'MERCHANT']);
  });

  it('rechaza negocios o ciudades que no existen', async () => {
    await http()
      .post(`${API}/admin/merchants`)
      .set(admin.auth)
      .send({ phone: '911000009', firstName: 'A', lastName: 'B', storeIds: ['st_nope'] })
      .expect(404);
    expect(await prisma.user.findUnique({ where: { phone: '911000009' } })).toBeNull();
    await http()
      .post(`${API}/admin/couriers`)
      .set(admin.auth)
      .send({ ...courierBody('911000008'), cityId: 'ci_nope' })
      .expect(404);
    await http()
      .post(`${API}/admin/couriers`)
      .set(admin.auth)
      .send({ ...courierBody('911000008'), vehicleType: 'AVION' })
      .expect(400);
  });

  it('da de alta un repartidor, y otra alta actualiza su vehículo', async () => {
    const res = await http().post(`${API}/admin/couriers`).set(admin.auth).send(courierBody(NEW_COURIER)).expect(201);
    expect((res.body.user as Partner).courier).toMatchObject({ vehicleLabel: 'Moto verde', status: 'OFFLINE' });

    const session = await logIn(app, NEW_COURIER);
    await http().get(`${API}/courier/me`).set(session.auth).expect(200);

    const updated = await http()
      .post(`${API}/admin/couriers`)
      .set(admin.auth)
      .send(courierBody(NEW_COURIER, 'Moto negra'))
      .expect(201);
    expect(updated.body.user.courier.vehicleLabel).toBe('Moto negra');
  });

  it('no suspende a un repartidor con un pedido en curso', async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: ORDER_STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: ORDER_STORE, ...h })) });
    const customer = await logIn(app, '984123456');
    const order = await http()
      .post(`${API}/orders`)
      .set(customer.auth)
      .send({
        storeId: ORDER_STORE,
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
    const courier = await prisma.courier.findFirstOrThrow({ where: { user: { phone: NEW_COURIER } } });
    await prisma.order.update({ where: { id: order.body.id }, data: { courierId: courier.id, status: 'ON_THE_WAY' } });

    const res = await suspend(courier.userId).expect(409);
    expect(res.body.code).toBe('COURIER_HAS_ACTIVE_ORDER');
    expect((await prisma.userRole.findMany({ where: { userId: courier.userId } })).map((r) => r.role)).toContain(
      'COURIER',
    );

    await prisma.order.update({ where: { id: order.body.id }, data: { status: 'CANCELLED' } });
  });

  it('suspender quita el rol, cierra las sesiones y pausa sus negocios', async () => {
    const merchant = await prisma.user.findUniqueOrThrow({ where: { phone: NEW_MERCHANT } });
    const session = await logIn(app, NEW_MERCHANT);

    const res = await suspend(merchant.id).expect(200);
    const user = res.body as Partner;
    expect(user.roles).toEqual(['CUSTOMER']);
    expect(user.stores).toEqual([expect.objectContaining({ id: TRANSFER_STORE, isAcceptingOrders: false })]);

    const refresh = await http().post(`${API}/auth/refresh`).send({ refreshToken: session.refreshToken });
    expect(refresh.status).toBe(401);
    // Al volver a entrar ya no tiene el rol.
    const again = await logIn(app, NEW_MERCHANT);
    await http().get(`${API}/merchant/stores`).set(again.auth).expect(403);
  });

  it('suspende solo el rol pedido y es idempotente', async () => {
    const courier = await prisma.user.findUniqueOrThrow({ where: { phone: NEW_COURIER } });
    await http()
      .post(`${API}/admin/merchants`)
      .set(admin.auth)
      .send({ phone: NEW_COURIER, firstName: 'Rosa', lastName: 'Huamán' })
      .expect(201);

    const res = await suspend(courier.id, { roles: ['COURIER'] }).expect(200);
    expect((res.body as Partner).roles.sort()).toEqual(['CUSTOMER', 'MERCHANT']);
    await suspend(courier.id, { roles: ['COURIER'] }).expect(200);
    await suspend(courier.id, { roles: ['ADMIN'] }).expect(400);
    await suspend('usr_nope').expect(404);
  });
});
