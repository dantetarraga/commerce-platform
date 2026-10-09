import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, sessionFor, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CUSTOMER = '984123456';
const pen = (amount: number) => ({ amount, currency: 'PEN' });

describe('Admin: ciudades (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let customer: TestSession;
  const created: string[] = [];
  const http = () => request(app.getHttpServer());

  const newCity = {
    name: 'Yauri Norte',
    region: 'Cusco',
    centerLat: -14.78,
    centerLng: -71.4,
    coverageKm: 4,
    maxDeliveryKm: 5,
    baseDeliveryFee: pen(300),
    feePerKm: pen(100),
    routeFactor: 1.3,
    avgSpeedKmh: 20,
  };

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    // El celular del admin ya agotó sus códigos OTP en otras suites.
    admin = await sessionFor(app, ADMIN);
    customer = await sessionFor(app, CUSTOMER);
  });

  afterAll(async () => {
    await prisma.city.deleteMany({ where: { id: { in: created } } });
    await app.close();
  });

  it('solo el admin', async () => {
    await http().get(`${API}/admin/cities`).set(customer.auth).expect(403);
  });

  it('lista las ciudades con sus conteos y ejemplos de tarifa calculados por el backend', async () => {
    const res = await http().get(`${API}/admin/cities`).set(admin.auth).expect(200);
    const city = res.body[0];
    expect(city).toMatchObject({
      baseDeliveryFee: { currency: 'PEN' },
      storeCount: expect.any(Number),
      courierCount: expect.any(Number),
    });
    expect(city.feeExamples).toHaveLength(3);
    expect(city.feeExamples[0]).toMatchObject({ straightKm: 1, fee: { currency: 'PEN' } });
  });

  it('crea una ciudad inactiva con slug propio y la edita', async () => {
    const res = await http().post(`${API}/admin/cities`).set(admin.auth).send(newCity).expect(201);
    created.push(res.body.id);
    expect(res.body).toMatchObject({ slug: 'yauri-norte', isActive: false, coverageKm: 4 });
    // 1 km recta × 1.3 = 1.3 km → 2 km cobrados: S/ 3 + 2 × S/ 1.
    expect(res.body.feeExamples[0].fee).toEqual(pen(500));

    const updated = await http()
      .patch(`${API}/admin/cities/${res.body.id}`)
      .set(admin.auth)
      .send({ feePerKm: pen(150), isActive: true })
      .expect(200);
    expect(updated.body).toMatchObject({ feePerKm: pen(150), isActive: true });
  });

  it('valida los rangos', async () => {
    const res = await http()
      .post(`${API}/admin/cities`)
      .set(admin.auth)
      .send({ ...newCity, routeFactor: 0.5 })
      .expect(400);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('una ciudad que no existe da 404', async () => {
    await http().patch(`${API}/admin/cities/no-existe`).set(admin.auth).send({ coverageKm: 3 }).expect(404);
  });
});
