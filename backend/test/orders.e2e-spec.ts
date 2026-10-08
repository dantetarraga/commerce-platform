import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

const PLAZA = { latitude: -14.7936, longitude: -71.4128 };
const pen = (amount: number) => ({ amount, currency: 'PEN' });

const ALL_DAY = Array.from({ length: 7 }, (_, dayOfWeek) => ({ dayOfWeek, opensAt: 0, closesAt: 1440 }));

/** Cuerpo como lo arma la app (`OrderJson.requestToJson`). */
function orderBody(overrides: Record<string, unknown> = {}) {
  return {
    storeId: 'st_chaski_dorado',
    items: [
      {
        productId: 'pr_pollo_cuarto',
        variantId: 'va_pc_pecho',
        optionValueIds: ['ov_pc_huevo'],
        quantity: 2,
        notes: '',
      },
    ],
    address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: 'Puerta verde', ...PLAZA },
    payment: { type: 'CASH', changeFor: pen(10000) },
    couponCode: null,
    scheduledFor: null,
    tip: pen(200),
    notes: 'Tocar el timbre',
    ...overrides,
  };
}

describe('Cupones y pedidos (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let alex: TestSession;
  let rosa: TestSession;
  const http = () => request(app.getHttpServer());

  const touchedStores = ['st_chaski_dorado', 'st_pizzeria_qori', 'st_botica_salud'];
  let originalSchedules: { storeId: string; dayOfWeek: number; opensAt: number; closesAt: number }[];
  let originalMinOrder: number;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);

    originalSchedules = await prisma.storeSchedule.findMany({
      where: { storeId: { in: touchedStores } },
      select: { storeId: true, dayOfWeek: true, opensAt: true, closesAt: true },
    });
    originalMinOrder = (await prisma.store.findUniqueOrThrow({ where: { id: 'st_pizzeria_qori' } })).minOrderAmount;

    // Horarios fijos para no depender de la hora a la que corre el test.
    for (const storeId of ['st_chaski_dorado', 'st_pizzeria_qori']) {
      await prisma.storeSchedule.deleteMany({ where: { storeId } });
      await prisma.storeSchedule.createMany({ data: ALL_DAY.map((h) => ({ storeId, ...h })) });
    }
    await prisma.storeSchedule.deleteMany({ where: { storeId: 'st_botica_salud' } });
    await prisma.store.update({ where: { id: 'st_pizzeria_qori' }, data: { minOrderAmount: 100_000 } });

    alex = await signUp(app, '961000001');
    rosa = await signUp(app, '961000002');
  });

  // Deja los negocios como estaban: los otros specs leen el seed.
  afterAll(async () => {
    await prisma.storeSchedule.deleteMany({ where: { storeId: { in: touchedStores } } });
    await prisma.storeSchedule.createMany({ data: originalSchedules });
    await prisma.store.update({ where: { id: 'st_pizzeria_qori' }, data: { minOrderAmount: originalMinOrder } });
    await prisma.product.update({ where: { id: 'pr_pollo_medio' }, data: { stock: null } });
    await app.close();
  });

  describe('POST /coupons/validate', () => {
    const validate = (session: TestSession, code: string, subtotal: number, storeId = 'st_chaski_dorado') =>
      http()
        .post(`${API}/coupons/validate`)
        .set(session.auth)
        .send({ code, storeId, subtotal: pen(subtotal) });

    it('devuelve el descuento y la etiqueta', async () => {
      const res = await validate(alex, ' espinar ', 2000).expect(200);
      expect(res.body).toEqual({ code: 'ESPINAR', discount: pen(300), label: 'S/ 3 por pedir local' });
    });

    it('delivery gratis descuenta el delivery estimado', async () => {
      const res = await validate(alex, 'KANTUFREE', 3000, 'st_dulce_kantu').expect(200);
      expect(res.body.discount.amount).toBeGreaterThan(0);
    });

    it.each([
      ['NOEXISTE', 2000, 'st_chaski_dorado', 'COUPON_INVALID'],
      ['BIENVENIDA', 1000, 'st_chaski_dorado', 'COUPON_MIN_NOT_REACHED'],
      ['KANTUFREE', 5000, 'st_chaski_dorado', 'COUPON_NOT_APPLICABLE'],
    ])('%s con S/ %s → %s', async (code, subtotal, storeId, expected) => {
      const res = await validate(alex, code, subtotal, storeId).expect(422);
      expect(res.body.code).toBe(expected);
    });

    it('el mínimo sale en el mensaje, en soles', async () => {
      const res = await validate(alex, 'BIENVENIDA', 1000).expect(422);
      expect(res.body.message).toBe('BIENVENIDA aplica desde S/ 15.00 en productos.');
    });

    it('exige sesión', async () => {
      await http()
        .post(`${API}/coupons/validate`)
        .send({ code: 'ESPINAR', storeId: 'st_chaski_dorado', subtotal: pen(2000) })
        .expect(401);
    });
  });

  describe('POST /orders', () => {
    it('recalcula precios, aplica cupón y propina y devuelve el pedido como lo lee la app', async () => {
      const res = await http()
        .post(`${API}/orders`)
        .set(alex.auth)
        .set('Idempotency-Key', 'e2e-order-alex-0001')
        .send(orderBody({ couponCode: 'ESPINAR' }))
        .expect(201);

      const order = res.body;
      const fee = order.deliveryFee.amount as number;
      expect(order).toMatchObject({
        id: expect.any(String),
        code: expect.stringMatching(/^#\d+$/),
        store: { id: 'st_chaski_dorado', name: 'Pollería El Chaski Dorado', ownerName: 'Don Julián' },
        lines: [
          {
            productId: 'pr_pollo_cuarto',
            name: '1/4 de pollo a la brasa',
            quantity: 2,
            total: pen(4200), // (pecho 1900 + huevo 200) × 2
            description: 'Pecho · Huevo frito',
          },
        ],
        subtotal: pen(4200),
        discount: pen(300),
        tip: pen(200),
        total: pen(4200 + fee - 300 + 200),
        notes: 'Tocar el timbre',
        address: { title: 'Casa', street: 'Jr. Túpac Amaru 214', reference: 'Puerta verde' },
        payment: { type: 'CASH', changeFor: pen(10000) },
        status: 'RECEIVED',
        events: [{ status: 'RECEIVED', at: expect.any(String) }],
        placedAt: expect.any(String),
        courier: null,
        estimatedArrival: expect.any(String),
        scheduledFor: null,
        rating: null,
      });
      expect(fee).toBeGreaterThan(0);
    });

    it('con la misma Idempotency-Key devuelve el mismo pedido', async () => {
      const again = await http()
        .post(`${API}/orders`)
        .set(alex.auth)
        .set('Idempotency-Key', 'e2e-order-alex-0001')
        .send(orderBody({ couponCode: 'ESPINAR' }))
        .expect(201);
      const list = await http().get(`${API}/orders`).set(alex.auth).expect(200);
      expect(list.body.items).toHaveLength(1);
      expect(again.body.id).toBe(list.body.items[0].id);
    });

    it('un cupón ya usado y el de primer pedido se rechazan', async () => {
      const used = await http()
        .post(`${API}/orders`)
        .set(alex.auth)
        .send(orderBody({ couponCode: 'ESPINAR' }));
      expect(used.status).toBe(422);
      expect(used.body.code).toBe('COUPON_ALREADY_USED');

      const first = await http()
        .post(`${API}/orders`)
        .set(alex.auth)
        .send(orderBody({ couponCode: 'BIENVENIDO10' }));
      expect(first.body.code).toBe('COUPON_FIRST_ORDER_ONLY');
    });

    it.each([
      [
        'falta la variante',
        { items: [{ productId: 'pr_pollo_cuarto', optionValueIds: [], quantity: 1 }] },
        422,
        'INVALID_PRODUCT_OPTIONS',
      ],
      [
        'producto de otro negocio',
        { items: [{ productId: 'pr_pizza_andina', optionValueIds: [], quantity: 1 }] },
        409,
        'PRODUCT_UNAVAILABLE',
      ],
      [
        'negocio cerrado',
        { storeId: 'st_botica_salud', items: [{ productId: 'x', optionValueIds: [], quantity: 1 }] },
        409,
        'STORE_CLOSED',
      ],
      [
        'fuera de cobertura',
        { address: { title: 'Lejos', street: 'Cusco', latitude: -13.53, longitude: -71.97 } },
        422,
        'ADDRESS_OUT_OF_COVERAGE',
      ],
      ['vuelto insuficiente', { payment: { type: 'CASH', changeFor: pen(1000) } }, 422, 'CASH_CHANGE_TOO_LOW'],
      ['con tarjeta (solo contraentrega)', { payment: { type: 'CARD' } }, 422, 'PAYMENT_METHOD_UNAVAILABLE'],
      ['programado en el pasado', { scheduledFor: '2020-01-01T12:00:00.000Z' }, 422, 'SCHEDULE_INVALID'],
    ])('%s → %s', async (_label, overrides, status, code) => {
      const res = await http().post(`${API}/orders`).set(rosa.auth).send(orderBody(overrides)).expect(status);
      expect(res.body.code).toBe(code);
    });

    it('fuera de la zona de la ciudad lo dice con el nombre de la ciudad', async () => {
      const res = await http()
        .post(`${API}/orders`)
        .set(rosa.auth)
        .send(orderBody({ address: { title: 'Lejos', street: 'Cusco', latitude: -13.53, longitude: -71.97 } }))
        .expect(422);
      expect(res.body.message).toBe('Esa dirección está fuera de la zona de reparto de Espinar.');
    });

    it('bajo el pedido mínimo → MIN_ORDER_NOT_REACHED', async () => {
      const [variant] = await prisma.productVariant.findMany({ where: { productId: 'pr_pizza_americana' } });
      const res = await http()
        .post(`${API}/orders`)
        .set(rosa.auth)
        .send(
          orderBody({
            storeId: 'st_pizzeria_qori',
            items: [{ productId: 'pr_pizza_americana', variantId: variant.id, optionValueIds: [], quantity: 1 }],
          }),
        )
        .expect(422);
      expect(res.body.code).toBe('MIN_ORDER_NOT_REACHED');
    });

    it('descuenta stock y no vende más de lo que hay', async () => {
      await prisma.product.update({ where: { id: 'pr_pollo_medio' }, data: { stock: 2 } });
      const medio = (quantity: number) =>
        orderBody({
          items: [
            { productId: 'pr_pollo_cuarto', variantId: 'va_pc_pierna', optionValueIds: [], quantity: 1 },
            { productId: 'pr_pollo_medio', optionValueIds: [], quantity },
          ],
          payment: { type: 'YAPE' },
        });

      const tooMany = await http().post(`${API}/orders`).set(rosa.auth).send(medio(3)).expect(409);
      expect(tooMany.body.code).toBe('PRODUCT_OUT_OF_STOCK');

      await http().post(`${API}/orders`).set(rosa.auth).send(medio(2)).expect(201);
      const product = await prisma.product.findUniqueOrThrow({ where: { id: 'pr_pollo_medio' } });
      expect(product.stock).toBe(0);

      const soldOut = await http().post(`${API}/orders`).set(rosa.auth).send(medio(1)).expect(409);
      expect(soldOut.body.code).toBe('PRODUCT_UNAVAILABLE');
    });

    it('valida el cuerpo con errores por campo', async () => {
      const res = await http()
        .post(`${API}/orders`)
        .set(rosa.auth)
        .send(orderBody({ items: [], payment: { type: 'BITCOIN' }, tip: pen(-1) }))
        .expect(400);
      expect(Object.keys(res.body.details.fields)).toEqual(
        expect.arrayContaining(['items', 'payment.type', 'tip.amount']),
      );
    });
  });

  describe('GET /orders y /orders/:id', () => {
    it('cada cliente ve solo sus pedidos; uno ajeno es 404', async () => {
      const mine = await http().get(`${API}/orders`).set(alex.auth).expect(200);
      const [order] = mine.body.items;
      expect(mine.body.nextCursor).toBeNull();

      await http().get(`${API}/orders/${order.id}`).set(alex.auth).expect(200);
      const foreign = await http().get(`${API}/orders/${order.id}`).set(rosa.auth).expect(404);
      expect(foreign.body.message).toBe('No encontramos ese pedido.');
    });

    it('pagina con cursor, del más reciente al más antiguo', async () => {
      await http()
        .post(`${API}/orders`)
        .set(rosa.auth)
        .send(orderBody({ payment: { type: 'PLIN' } }))
        .expect(201);
      const first = await http().get(`${API}/orders`).query({ limit: 1 }).set(rosa.auth).expect(200);
      expect(first.body.items).toHaveLength(1);
      expect(first.body.nextCursor).toEqual(expect.any(String));

      const all = await http().get(`${API}/orders`).set(rosa.auth).expect(200);
      const dates = all.body.items.map((o: { placedAt: string }) => o.placedAt);
      expect(dates).toEqual([...dates].sort().reverse());
    });
  });

  describe('POST /orders/:id/rating', () => {
    it('solo cuando está entregado, una vez, y actualiza el rating del negocio', async () => {
      const { body } = await http().get(`${API}/orders`).set(alex.auth).expect(200);
      const orderId = body.items[0].id as string;

      const early = await http().post(`${API}/orders/${orderId}/rating`).set(alex.auth).send({ rating: 5 }).expect(409);
      expect(early.body.code).toBe('ORDER_NOT_DELIVERED');

      const before = await prisma.store.findUniqueOrThrow({ where: { id: 'st_chaski_dorado' } });
      await prisma.order.update({ where: { id: orderId }, data: { status: 'DELIVERED' } });

      const rated = await http()
        .post(`${API}/orders/${orderId}/rating`)
        .set(alex.auth)
        .send({ rating: 5, comment: 'Llegó calientito' })
        .expect(200);
      expect(rated.body.rating).toBe(5);

      const after = await prisma.store.findUniqueOrThrow({ where: { id: 'st_chaski_dorado' } });
      expect(after.ratingCount).toBe(before.ratingCount + 1);

      const twice = await http().post(`${API}/orders/${orderId}/rating`).set(alex.auth).send({ rating: 4 }).expect(409);
      expect(twice.body.code).toBe('ORDER_ALREADY_RATED');
    });

    it('rating fuera de 1..5 → 400', async () => {
      await http().post(`${API}/orders/cualquiera/rating`).set(alex.auth).send({ rating: 6 }).expect(400);
    });
  });
});
