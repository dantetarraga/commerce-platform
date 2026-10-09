import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, sessionFor, signUp } from './helpers';
import { createTestApp } from './test-app';

const MERCHANT = '910000000';
const STORE = 'st_chaski_dorado';
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

describe('Eliminar la cuenta (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: STORE },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId: STORE, ...h })) });
  });

  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: STORE } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await app.close();
  });

  it('borra los datos personales, cierra la sesión y deja el celular libre', async () => {
    const customer = await signUp(app, '965000401');
    await http().delete(`${API}/users/me`).set(customer.auth).expect(204);

    const deleted = await prisma.user.findUniqueOrThrow({ where: { id: customer.user.id } });
    expect(deleted).toMatchObject({ isActive: false, firstName: 'Cuenta', email: null });
    expect(deleted.phone).not.toBe('965000401');
    expect(await prisma.refreshToken.count({ where: { userId: customer.user.id } })).toBe(0);
    await http().get(`${API}/users/me`).set(customer.auth).expect(401);

    // Registrarse otra vez con el mismo celular crea una cuenta nueva.
    const again = await signUp(app, '965000401');
    expect(again.user.id).not.toBe(customer.user.id);
  });

  it('no deja eliminar con un pedido en curso', async () => {
    const customer = await signUp(app, '965000402');
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
    const res = await http().delete(`${API}/users/me`).set(customer.auth).expect(409);
    expect(res.body.code).toBe('ACCOUNT_HAS_ACTIVE_ORDER');
  });

  it('un socio se da de baja con Apamuy', async () => {
    const merchant = await sessionFor(app, MERCHANT);
    const res = await http().delete(`${API}/users/me`).set(merchant.auth).expect(409);
    expect(res.body.code).toBe('PARTNER_ACCOUNT');
  });
});
