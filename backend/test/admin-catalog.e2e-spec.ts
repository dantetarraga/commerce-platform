import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CHASKI_OWNER = '910000000'; // tiene rol de negocio en el seed
const CUSTOMER = '984123456'; // sin rol de negocio
const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));
const soles = (amount: number) => ({ amount, currency: 'PEN' });

type AdminProduct = {
  id: string;
  variants: { id: string; name: string; price: { amount: number } }[];
  options: { id: string; name: string; values: { id: string; name: string }[] }[];
};

describe('Admin: catálogo (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let cityId: string;
  let ownerId: string;
  let storeId: string;
  let sectionId: string;
  let product: AdminProduct;
  const categoryIds: string[] = [];
  const http = () => request(app.getHttpServer());
  const asAdmin = {
    get: (path: string) => http().get(`${API}/admin/${path}`).set(admin.auth),
    post: (path: string, body: object) => http().post(`${API}/admin/${path}`).set(admin.auth).send(body),
    patch: (path: string, body: object) => http().patch(`${API}/admin/${path}`).set(admin.auth).send(body),
    put: (path: string, body: object) => http().put(`${API}/admin/${path}`).set(admin.auth).send(body),
    delete: (path: string) => http().delete(`${API}/admin/${path}`).set(admin.auth),
  };
  const publicIds = async () => {
    const res = await http().get(`${API}/stores`).query({ limit: 50 }).expect(200);
    return (res.body.items as { id: string }[]).map((s) => s.id);
  };

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await logIn(app, ADMIN);
    cityId = (await prisma.city.findFirstOrThrow()).id;
    ownerId = (await prisma.user.findUniqueOrThrow({ where: { phone: CHASKI_OWNER } })).id;
  });

  afterAll(async () => {
    if (storeId) {
      await prisma.product.deleteMany({ where: { storeId } });
      await prisma.store.delete({ where: { id: storeId } });
    }
    await prisma.category.deleteMany({ where: { id: { in: categoryIds } } });
    await app.close();
  });

  it('solo el admin edita el catálogo', async () => {
    const merchant = await logIn(app, CHASKI_OWNER);
    await http().get(`${API}/admin/stores`).set(merchant.auth).expect(403);
  });

  it('crea una categoría con slug a partir del nombre', async () => {
    const res = await asAdmin.post('categories', { name: 'Quesería Andina', sortOrder: 90 }).expect(201);
    expect(res.body).toMatchObject({ name: 'Quesería Andina', slug: 'queseria-andina' });
    categoryIds.push(res.body.id);
    const dup = await asAdmin.post('categories', { name: 'Quesería andina' }).expect(409);
    expect(dup.body.code).toBe('CONFLICT');
  });

  it('valida dueño, horario y categorías al crear', async () => {
    const base = { cityId, name: 'Lácteos Kana', addressLine: 'Jr. Lima 120', latitude: -14.7936, longitude: -71.4128 };
    const customer = await prisma.user.findUniqueOrThrow({ where: { phone: CUSTOMER } });
    const noRole = await asAdmin.post('stores', { ...base, ownerId: customer.id }).expect(400);
    expect(noRole.body.details.fields.ownerId).toMatch(/rol de negocio/);

    const overlap = await asAdmin
      .post('stores', {
        ...base,
        ownerId,
        schedules: [
          { dayOfWeek: 1, opensAt: 420, closesAt: 900 },
          { dayOfWeek: 1, opensAt: 840, closesAt: 1380 },
        ],
      })
      .expect(400);
    expect(overlap.body.details.fields).toEqual({ 'schedules.1': 'Este turno se cruza con otro.' });

    await asAdmin.post('stores', { ...base, ownerId, categoryIds: ['cat_nope'] }).expect(400);
    await asAdmin.post('stores', { ...base, ownerId, latitude: 200 }).expect(400);
  });

  it('un negocio nuevo queda en borrador y no aparece en la app', async () => {
    const res = await asAdmin
      .post('stores', {
        cityId,
        ownerId,
        name: 'Lácteos Kana',
        addressLine: 'Jr. Lima 120',
        latitude: -14.7936,
        longitude: -71.4128,
        minOrderAmount: soles(1000),
        categoryIds,
        schedules: ALL_DAY,
      })
      .expect(201);
    storeId = res.body.id;
    expect(res.body).toMatchObject({
      slug: 'lacteos-kana',
      isActive: false,
      minOrderAmount: soles(1000),
      categoryIds,
      schedules: ALL_DAY,
    });
    expect(await publicIds()).not.toContain(storeId);
    await http().get(`${API}/stores/${storeId}`).expect(404);
  });

  it('arma la carta: sección y producto con variantes y opciones', async () => {
    const section = await asAdmin.post(`stores/${storeId}/sections`, { name: 'Quesos' }).expect(201);
    sectionId = section.body.id;

    const bad = await asAdmin
      .post(`stores/${storeId}/products`, {
        name: 'Queso fresco',
        basePrice: soles(1500),
        options: [{ name: 'Tamaño', minSelect: 2, maxSelect: 1, values: [{ name: 'Chico' }] }],
      })
      .expect(400);
    expect(bad.body.details.fields['options.0.minSelect']).toBeDefined();

    const res = await asAdmin
      .post(`stores/${storeId}/products`, {
        menuSectionId: sectionId,
        name: 'Queso fresco de Kana',
        basePrice: soles(1500),
        isLocal: true,
        variants: [
          { name: 'Medio kilo', price: soles(1500) },
          { name: 'Un kilo', price: soles(2800) },
        ],
        options: [
          {
            name: 'Acompañamiento',
            minSelect: 0,
            maxSelect: 2,
            values: [{ name: 'Mote', priceDelta: soles(300) }, { name: 'Choclo' }, { name: 'Papa' }],
          },
        ],
      })
      .expect(201);
    product = res.body as AdminProduct;
    expect(product.variants.map((v) => v.name)).toEqual(['Medio kilo', 'Un kilo']);
    expect(product.options[0].values.map((v) => v.name)).toEqual(['Mote', 'Choclo', 'Papa']);
  });

  it('editar conserva los ids de lo que sigue y borra lo que falta', async () => {
    const [half, kilo] = product.variants;
    const [option] = product.options;
    const [mote, , papa] = option.values;
    const res = await asAdmin
      .patch(`products/${product.id}`, {
        variants: [
          { id: kilo.id, name: 'Un kilo', price: soles(2600) },
          { name: 'Cuarto', price: soles(800) },
        ],
        options: [
          {
            id: option.id,
            name: 'Acompañamiento',
            minSelect: 0,
            maxSelect: 2,
            values: [
              { id: papa.id, name: 'Papa sancochada' },
              { id: mote.id, name: 'Mote' },
            ],
          },
        ],
      })
      .expect(200);
    const updated = res.body as AdminProduct;
    expect(updated.variants.map((v) => [v.id === kilo.id, v.name, v.price.amount])).toEqual([
      [true, 'Un kilo', 2600],
      [false, 'Cuarto', 800],
    ]);
    expect(updated.variants.some((v) => v.id === half.id)).toBe(false);
    expect(updated.options[0].values.map((v) => [v.id, v.name])).toEqual([
      [papa.id, 'Papa sancochada'],
      [mote.id, 'Mote'],
    ]);

    const foreign = await asAdmin.patch(`products/${product.id}`, {
      variants: [{ id: 'var_otro', name: 'X', price: soles(1) }],
    });
    expect(foreign.status).toBe(400);
    product = updated;
  });

  it('al publicarlo, la app lo muestra con su carta', async () => {
    await asAdmin.patch(`stores/${storeId}`, { isActive: true, promoLabel: 'Queso del día' }).expect(200);
    expect(await publicIds()).toContain(storeId);
    const store = await http().get(`${API}/stores/${storeId}`).expect(200);
    expect(store.body).toMatchObject({ name: 'Lácteos Kana', isOpenNow: true, promoLabel: 'Queso del día' });

    const menu = await http().get(`${API}/stores/${storeId}/products`).expect(200);
    expect(menu.body.sections).toEqual([
      expect.objectContaining({
        id: sectionId,
        products: [expect.objectContaining({ id: product.id, price: soles(800), hasChoices: true })],
      }),
    ]);
  });

  it('el horario se reemplaza completo y se valida', async () => {
    const lunes = [{ dayOfWeek: 1, opensAt: 480, closesAt: 1200 }];
    const res = await asAdmin.put(`stores/${storeId}/schedules`, { schedules: lunes }).expect(200);
    expect(res.body.schedules).toEqual(lunes);
    await asAdmin
      .put(`stores/${storeId}/schedules`, { schedules: [{ dayOfWeek: 1, opensAt: 600, closesAt: 600 }] })
      .expect(400);
    await asAdmin.put(`stores/${storeId}/schedules`, { schedules: ALL_DAY }).expect(200);
  });

  it('quitar producto o sección no rompe la carta', async () => {
    await asAdmin.delete(`sections/${sectionId}`).expect(204);
    const detail = await asAdmin.get(`stores/${storeId}`).expect(200);
    expect(detail.body.sections).toEqual([]);
    expect(detail.body.products[0].menuSectionId).toBeNull();

    await asAdmin.delete(`products/${product.id}`).expect(204);
    await asAdmin.get(`products/${product.id}`).expect(404);
    const after = await asAdmin.get(`stores/${storeId}`).expect(200);
    expect(after.body.products).toEqual([]);
  });

  it('quitar el negocio lo oculta de la app', async () => {
    await asAdmin.delete(`stores/${storeId}`).expect(204);
    expect(await publicIds()).not.toContain(storeId);
    await asAdmin.get(`stores/${storeId}`).expect(404);
  });
});
