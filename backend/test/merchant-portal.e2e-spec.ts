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
    await prisma.product.deleteMany({ where: { storeId: STORE, name: { startsWith: 'Importado' } } });
    await prisma.menuSection.deleteMany({ where: { storeId: STORE, name: 'Importados e2e' } });
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

  it('importa productos: revisa sin guardar, rechaza errores y guarda todo junto', async () => {
    const url = `${API}/merchant/catalog/stores/${STORE}/products/import`;
    const rows = [
      { line: 2, name: 'Importado chicha 1 L', price: '8,50', section: 'Importados e2e' },
      { line: 3, name: 'Importado emoliente', price: 'S/ 2', stock: '10', section: 'importados E2E' },
    ];
    const preview = await http().post(url).set(merchant.auth).send({ rows, dryRun: true }).expect(200);
    expect(preview.body).toMatchObject({ dryRun: true, created: 2, failed: 0, sectionsCreated: ['Importados e2e'] });
    expect(await prisma.product.count({ where: { storeId: STORE, name: { startsWith: 'Importado' } } })).toBe(0);

    const bad = await http()
      .post(url)
      .set(merchant.auth)
      .send({ rows: [...rows, { line: 4, name: 'Importado sin precio' }] })
      .expect(400);
    expect(bad.body.details.rows).toEqual([expect.objectContaining({ line: 4, action: 'error' })]);

    const saved = await http().post(url).set(merchant.auth).send({ rows }).expect(200);
    expect(saved.body).toMatchObject({ dryRun: false, created: 2 });
    const products = await prisma.product.findMany({
      where: { storeId: STORE, name: { startsWith: 'Importado' } },
      select: { basePrice: true, stock: true, menuSection: { select: { name: true } } },
      orderBy: { name: 'asc' },
    });
    expect(products).toEqual([
      { basePrice: 850, stock: null, menuSection: { name: 'Importados e2e' } },
      { basePrice: 200, stock: 10, menuSection: { name: 'Importados e2e' } },
    ]);

    // La segunda vez reconoce los productos por su nombre y solo cambia el precio.
    const again = await http()
      .post(url)
      .set(merchant.auth)
      .send({ rows: [{ line: 2, name: 'importado CHICHA 1 l', price: '9' }] })
      .expect(200);
    expect(again.body).toMatchObject({ created: 0, updated: 1 });
    expect(again.body.rows[0]).toMatchObject({
      changes: expect.arrayContaining(['price']),
      price: { from: { amount: 850, currency: 'PEN' }, to: { amount: 900, currency: 'PEN' } },
    });

    await http().post(url).set(otherMerchant.auth).send({ rows, dryRun: true }).expect(404);

    // Una carta grande (más de 100 KB) entra entera.
    const big = Array.from({ length: 400 }, (_, i) => ({
      line: i + 2,
      name: `Importado grande ${i}`,
      price: '10',
      description: 'x'.repeat(400),
    }));
    const bigPreview = await http().post(url).set(merchant.auth).send({ rows: big, dryRun: true }).expect(200);
    expect(bigPreview.body.created).toBe(400);
  });

  it('ordena las secciones de su carta; pide todas y solo las suyas', async () => {
    const url = `${API}/merchant/catalog/stores/${STORE}/sections/order`;
    const sections = await prisma.menuSection.findMany({
      where: { storeId: STORE },
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    const ids = sections.map((s) => s.id);
    const reversed = [...ids].reverse();

    const res = await http().put(url).set(merchant.auth).send({ sectionIds: reversed }).expect(200);
    expect(res.body.map((s: { id: string }) => s.id)).toEqual(reversed);

    await http()
      .put(url)
      .set(merchant.auth)
      .send({ sectionIds: reversed.slice(1) })
      .expect(400);
    await http().put(url).set(otherMerchant.auth).send({ sectionIds: reversed }).expect(404);
    await http().put(url).set(merchant.auth).send({ sectionIds: ids }).expect(200);
  });

  it('pide la URL para subir una foto solo de su negocio', async () => {
    const body = { purpose: 'product', storeId: STORE, contentType: 'image/webp', size: 120_000 };
    // En test no hay storage: responde que la subida no está activada.
    const res = await http().post(`${API}/uploads/images`).set(merchant.auth).send(body).expect(503);
    expect(res.body.code).toBe('STORAGE_NOT_CONFIGURED');
    await http()
      .post(`${API}/uploads/images`)
      .set(merchant.auth)
      .send({ ...body, storeId: QORI })
      .expect(404);
    await http()
      .post(`${API}/uploads/images`)
      .set(merchant.auth)
      .send({ purpose: 'promotion', contentType: 'image/webp', size: 1000 })
      .expect(403);
    await http()
      .post(`${API}/uploads/images`)
      .set(merchant.auth)
      .send({ ...body, contentType: 'image/gif', size: 10 * 1024 * 1024 })
      .expect(400);
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
