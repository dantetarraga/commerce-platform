import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { createTestApp } from './test-app';

const API = '/api/v1';
const PLAZA = { lat: -14.7936, lng: -71.4128 };
const money = { amount: expect.any(Number), currency: 'PEN' };

describe('Catálogo (e2e)', () => {
  let app: INestApplication<App>;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health', async () => {
    await http().get(`${API}/health`).expect(200, { status: 'ok', database: 'up' });
  });

  it('GET /categories en orden', async () => {
    const res = await http().get(`${API}/categories`).expect(200);
    expect(res.body[0]).toEqual({ id: 'cat_restaurantes', name: 'Restaurantes', slug: 'restaurantes', iconUrl: null });
    expect(res.body).toHaveLength(8);
  });

  describe('GET /stores', () => {
    it('devuelve el StoreSummaryDto de la app, paginado', async () => {
      const res = await http()
        .get(`${API}/stores`)
        .query({ ...PLAZA, limit: 3 })
        .expect(200);
      expect(res.body).toMatchObject({ page: 1, limit: 3, total: 11 });
      expect(res.body.items).toHaveLength(3);
      const [first] = res.body.items;
      expect(first.promoLabel === null || typeof first.promoLabel === 'string').toBe(true);
      expect(first).toEqual({
        id: expect.any(String),
        name: expect.any(String),
        logoUrl: expect.any(String),
        coverUrl: expect.any(String),
        categoryIds: expect.any(Array),
        ratingAvg: expect.any(Number),
        ratingCount: expect.any(Number),
        distanceKm: expect.any(Number),
        etaMinutes: expect.any(Number),
        estimatedDeliveryFee: money,
        minOrderAmount: money,
        isOpenNow: expect.any(Boolean),
        deliversToYou: true,
        tags: expect.any(Array),
        promoLabel: first.promoLabel,
      });
    });

    it('ordena por distancia, popularidad o rating', async () => {
      const list = async (sort: string) =>
        (
          await http()
            .get(`${API}/stores`)
            .query({ ...PLAZA, sort, limit: 50 })
            .expect(200)
        ).body.items as {
          id: string;
          distanceKm: number;
          ratingAvg: number;
        }[];

      const byDistance = (await list('distance')).map((s) => s.distanceKm);
      expect(byDistance).toEqual([...byDistance].sort((a, b) => a - b));

      const byRating = (await list('rating')).map((s) => s.ratingAvg);
      expect(byRating).toEqual([...byRating].sort((a, b) => b - a));

      expect((await list('popular')).slice(0, 2).map((s) => s.id)).toEqual(['st_dona_rosa', 'st_chaski_dorado']); // 99 y 98 en el seed
    });

    it('filtra por categoría', async () => {
      const res = await http()
        .get(`${API}/stores`)
        .query({ ...PLAZA, categoryId: 'cat_licores' })
        .expect(200);
      expect(res.body.items.map((s: { id: string }) => s.id)).toEqual(['st_bodega_wayki']);
    });

    it('lejos de la ciudad no hay cobertura, salvo con includeOutOfCoverage', async () => {
      const far = { lat: PLAZA.lat + 0.2, lng: PLAZA.lng };
      const covered = await http().get(`${API}/stores`).query(far).expect(200);
      expect(covered.body.total).toBe(0);

      const all = await http()
        .get(`${API}/stores`)
        .query({ ...far, includeOutOfCoverage: true })
        .expect(200);
      expect(all.body.total).toBe(11);
      expect(all.body.items.every((s: { deliversToYou: boolean }) => !s.deliversToYou)).toBe(true);
    });

    it('valida el query', async () => {
      const res = await http().get(`${API}/stores`).query({ lat: 'abc', sort: 'cheap' }).expect(400);
      expect(Object.keys(res.body.details.fields).sort()).toEqual(['lat', 'lng', 'sort']);
    });
  });

  it('GET /stores/:id con horarios y datos del dueño', async () => {
    const res = await http().get(`${API}/stores/st_chaski_dorado`).expect(200);
    expect(res.body).toMatchObject({
      id: 'st_chaski_dorado',
      addressLine: 'Av. Túpac Amaru 245, Yauri',
      ownerName: 'Don Julián',
      attendingSince: 2011,
      promoLabel: '2x1 los martes',
    });
    expect(res.body.schedules).toContainEqual({ dayOfWeek: 1, opensAt: 660, closesAt: 1380 });
  });

  it('GET /stores/:id inexistente → 404 en español', async () => {
    const res = await http().get(`${API}/stores/st_nope`).expect(404);
    expect(res.body).toMatchObject({ code: 'NOT_FOUND', message: 'Este negocio ya no está disponible.' });
  });

  it('GET /stores/:id/products agrupa por sección con precio "desde"', async () => {
    const res = await http().get(`${API}/stores/st_chaski_dorado/products`).expect(200);
    expect(res.body.sections.map((s: { id: string }) => s.id)).toEqual([
      'ms_cd_pollos',
      'ms_cd_combos',
      'ms_cd_bebidas',
    ]);
    const cuarto = res.body.sections[0].products.find((p: { id: string }) => p.id === 'pr_pollo_cuarto');
    expect(cuarto).toEqual({
      id: 'pr_pollo_cuarto',
      name: '1/4 de pollo a la brasa',
      description: 'Pierna o pecho, con papas y ensalada.',
      imageUrl: expect.any(String),
      price: { amount: 1800, currency: 'PEN' }, // la variante más barata
      isAvailable: true,
      hasChoices: true,
      isFeatured: true,
    });
  });

  it('GET /products/:id con variantes, opciones y resumen del negocio', async () => {
    const res = await http().get(`${API}/products/pr_pollo_cuarto`).expect(200);
    expect(res.body).toMatchObject({
      id: 'pr_pollo_cuarto',
      storeId: 'st_chaski_dorado',
      storeName: 'Pollería El Chaski Dorado',
      basePrice: { amount: 1800, currency: 'PEN' },
      isAvailable: true,
      variants: [
        { id: 'va_pc_pierna', name: 'Pierna', price: { amount: 1800, currency: 'PEN' }, isAvailable: true },
        { id: 'va_pc_pecho', name: 'Pecho', price: { amount: 1900, currency: 'PEN' }, isAvailable: true },
      ],
      options: [
        {
          id: 'op_pc_extra',
          minSelect: 0,
          maxSelect: 2,
          values: [
            { id: 'ov_pc_huevo', name: 'Huevo frito', priceDelta: { amount: 200, currency: 'PEN' }, isAvailable: true },
            {
              id: 'ov_pc_platano',
              name: 'Plátano frito',
              priceDelta: { amount: 300, currency: 'PEN' },
              isAvailable: true,
            },
          ],
        },
      ],
      store: {
        deliveryFee: money,
        minOrderAmount: { amount: 1500, currency: 'PEN' },
        etaMinutes: expect.any(Number),
        isOpenNow: expect.any(Boolean),
      },
    });
  });

  it('GET /promotions con el cupón asociado', async () => {
    const res = await http().get(`${API}/promotions`).expect(200);
    expect(res.body).toContainEqual({
      id: 'promo_delivery',
      title: 'Delivery gratis',
      subtitle: 'En Dulce Kantu por compras desde S/ 30',
      imageUrl: expect.any(String),
      storeId: 'st_dulce_kantu',
      couponCode: 'KANTUFREE',
    });
  });

  describe('Búsqueda', () => {
    it('sin tildes ni mayúsculas', async () => {
      const res = await http()
        .get(`${API}/search`)
        .query({ q: 'PLATANO', ...PLAZA })
        .expect(200);
      expect(res.body).toEqual({ stores: expect.any(Array), products: expect.any(Array) });

      const accented = await http()
        .get(`${API}/search`)
        .query({ q: 'menu', ...PLAZA })
        .expect(200);
      const names: string[] = accented.body.products.map((p: { name: string }) => p.name);
      expect(names.some((name) => name.includes('Menú'))).toBe(true);
    });

    it('tolera errores de tipeo y devuelve negocios con el resumen', async () => {
      const res = await http()
        .get(`${API}/search`)
        .query({ q: 'polleria', ...PLAZA })
        .expect(200);
      expect(res.body.stores[0]).toMatchObject({ id: 'st_chaski_dorado', etaMinutes: expect.any(Number) });
    });

    it('los productos traen el negocio que los vende', async () => {
      const res = await http()
        .get(`${API}/search`)
        .query({ q: 'pollo', ...PLAZA })
        .expect(200);
      expect(res.body.products[0]).toMatchObject({
        storeId: 'st_chaski_dorado',
        storeName: 'Pollería El Chaski Dorado',
        price: money,
        hasChoices: expect.any(Boolean),
      });
    });

    it('trata % y _ como texto, no como comodines', async () => {
      const res = await http()
        .get(`${API}/search`)
        .query({ q: '%%', ...PLAZA })
        .expect(200);
      expect(res.body).toEqual({ stores: [], products: [] });
    });

    it('exige al menos 2 letras', async () => {
      await http().get(`${API}/search`).query({ q: ' a ' }).expect(400);
    });
  });

  it('GET /discovery/local-products', async () => {
    const res = await http().get(`${API}/discovery/local-products`).expect(200);
    expect(res.body.items.length).toBeGreaterThan(0);
    expect(res.body.items[0]).toMatchObject({
      storeId: expect.any(String),
      storeName: expect.any(String),
      price: money,
    });
  });

  it('GET /discovery/popular-searches solo con términos que alguien vende', async () => {
    const res = await http().get(`${API}/discovery/popular-searches`).expect(200);
    expect(res.body).toContainEqual({ term: 'Pollo a la brasa', storeCount: 1 });
    expect(res.body.every((t: { storeCount: number }) => t.storeCount > 0)).toBe(true);
  });

  it('ruta inexistente → 404 con el formato estándar', async () => {
    const res = await http().get(`${API}/nope`).expect(404);
    expect(res.body).toMatchObject({ statusCode: 404, code: 'NOT_FOUND' });
  });
});
