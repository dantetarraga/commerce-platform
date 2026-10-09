import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, sessionFor, TestSession } from './helpers';
import { createTestApp } from './test-app';

// Usuarios del seed. Con sessionFor: sus códigos OTP se agotan en otras suites.
const CHASKI_OWNER = '910000000';
const QORI_OWNER = '910000001';
const STORE = 'st_chaski_dorado';
const QORI = 'st_pizzeria_qori';

describe('Portal Socios: catálogo y reportes (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let merchant: TestSession;
  let otherMerchant: TestSession;
  let original: { description: string | null; avgPrepMinutes: number };
  const productIds: string[] = [];
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    merchant = await sessionFor(app, CHASKI_OWNER);
    otherMerchant = await sessionFor(app, QORI_OWNER);
    original = await prisma.store.findUniqueOrThrow({
      where: { id: STORE },
      select: { description: true, avgPrepMinutes: true },
    });
  });

  afterAll(async () => {
    await prisma.store.update({ where: { id: STORE }, data: original });
    await prisma.product.deleteMany({ where: { id: { in: productIds } } });
    await app.close();
  });

  it('el dueño ve su negocio con la carta; uno ajeno da 404', async () => {
    const res = await http().get(`${API}/merchant/catalog/stores/${STORE}`).set(merchant.auth).expect(200);
    expect(res.body).toMatchObject({ id: STORE, products: expect.any(Array), sections: expect.any(Array) });
    await http().get(`${API}/merchant/catalog/stores/${QORI}`).set(merchant.auth).expect(404);
  });

  it('cambia la descripción y el tiempo de preparación, pero no el nombre', async () => {
    const res = await http()
      .patch(`${API}/merchant/catalog/stores/${STORE}`)
      .set(merchant.auth)
      .send({ description: 'Pollos a la leña desde 1998', avgPrepMinutes: 25 })
      .expect(200);
    expect(res.body).toMatchObject({ description: 'Pollos a la leña desde 1998', avgPrepMinutes: 25 });

    await http()
      .patch(`${API}/merchant/catalog/stores/${STORE}`)
      .set(merchant.auth)
      .send({ name: 'Otro nombre' })
      .expect(400);
    await http()
      .patch(`${API}/merchant/catalog/stores/${STORE}`)
      .set(otherMerchant.auth)
      .send({ avgPrepMinutes: 10 })
      .expect(404);
  });

  it('crea un producto en su carta y otro dueño no puede editarlo', async () => {
    const res = await http()
      .post(`${API}/merchant/catalog/stores/${STORE}/products`)
      .set(merchant.auth)
      .send({ name: 'Chicha morada 1 L', basePrice: { amount: 800, currency: 'PEN' } })
      .expect(201);
    productIds.push(res.body.id);
    await http()
      .patch(`${API}/merchant/catalog/products/${res.body.id}`)
      .set(otherMerchant.auth)
      .send({ name: 'Robado' })
      .expect(404);
  });

  it('el reporte trae cada día del rango y el periodo anterior', async () => {
    const res = await http()
      .get(`${API}/merchant/reports`)
      .query({ from: '2026-10-01', to: '2026-10-07' })
      .set(merchant.auth)
      .expect(200);
    expect(res.body.salesByDay).toHaveLength(7);
    expect(res.body.previous).toMatchObject({ from: '2026-09-24', to: '2026-09-30' });
    expect(res.body.sales).toMatchObject({ currency: 'PEN' });

    await http()
      .get(`${API}/merchant/reports`)
      .query({ from: '2026-10-07', to: '2026-10-01' })
      .set(merchant.auth)
      .expect(400);
    await http()
      .get(`${API}/merchant/reports`)
      .query({ from: '2026-10-01', to: '2026-10-07', storeId: QORI })
      .set(merchant.auth)
      .expect(404);
  });

  it('la rendición trae cada día y deja la comisión pendiente', async () => {
    const res = await http()
      .get(`${API}/merchant/settlement`)
      .query({ from: '2026-10-01', to: '2026-10-03' })
      .set(merchant.auth)
      .expect(200);
    expect(res.body.days).toHaveLength(3);
    expect(res.body).toMatchObject({
      commission: null,
      collected: { total: { currency: 'PEN' }, CASH: { currency: 'PEN' } },
    });
  });
});
