import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, logIn, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CUSTOMER = '984123456';
const STORE = 'st_chaski_dorado';
const pen = (amount: number) => ({ amount, currency: 'PEN' });
const DAY = 24 * 60 * 60 * 1000;
const yesterday = () => new Date(Date.now() - DAY).toISOString();
const nextWeek = () => new Date(Date.now() + 7 * DAY).toISOString();

describe('Admin: cupones y promociones (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let customer: TestSession;
  let cityId: string;
  const couponIds: string[] = [];
  const promotionIds: string[] = [];
  const http = () => request(app.getHttpServer());
  const post = (path: string, body: object) => http().post(`${API}/admin/${path}`).set(admin.auth).send(body);
  const patch = (path: string, body: object) => http().patch(`${API}/admin/${path}`).set(admin.auth).send(body);
  const validate = (code: string, subtotal: number) =>
    http()
      .post(`${API}/coupons/validate`)
      .set(customer.auth)
      .send({ code, storeId: STORE, subtotal: pen(subtotal) });

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await logIn(app, ADMIN);
    customer = await logIn(app, CUSTOMER);
    cityId = (await prisma.city.findFirstOrThrow()).id;
  });

  afterAll(async () => {
    await prisma.promotion.deleteMany({ where: { id: { in: promotionIds } } });
    await prisma.coupon.deleteMany({ where: { id: { in: couponIds } } });
    await app.close();
  });

  it('solo el admin', async () => {
    await http().get(`${API}/admin/coupons`).set(customer.auth).expect(403);
  });

  it('crea un cupón de monto fijo que el cliente puede usar', async () => {
    const res = await post('coupons', {
      code: ' pollo4 ',
      label: 'S/ 4 en pollos',
      type: 'FIXED_AMOUNT',
      amountOff: pen(400),
      minOrderAmount: pen(2000),
      storeId: STORE,
      startsAt: yesterday(),
      endsAt: nextWeek(),
    }).expect(201);
    couponIds.push(res.body.id);
    expect(res.body).toMatchObject({
      code: 'POLLO4',
      type: 'FIXED_AMOUNT',
      amountOff: pen(400),
      percentOff: null,
      usedCount: 0,
    });

    expect((await validate('pollo4', 2500).expect(200)).body).toEqual({
      code: 'POLLO4',
      discount: pen(400),
      label: 'S/ 4 en pollos',
    });
    expect((await validate('POLLO4', 1000).expect(422)).body.code).toBe('COUPON_MIN_NOT_REACHED');

    const dup = await post('coupons', {
      code: 'POLLO4',
      label: 'Otro',
      type: 'FREE_DELIVERY',
      startsAt: yesterday(),
      endsAt: nextWeek(),
    }).expect(409);
    expect(dup.body.code).toBe('CONFLICT');
  });

  it('valida que el descuento calce con el tipo y las fechas', async () => {
    const base = { code: 'MAL10', label: 'Mal', startsAt: yesterday(), endsAt: nextWeek() };
    const noPercent = await post('coupons', { ...base, type: 'PERCENTAGE' }).expect(400);
    expect(noPercent.body.details.fields).toEqual({ percentOff: 'Indica el porcentaje de descuento.' });
    await post('coupons', { ...base, type: 'FREE_DELIVERY', amountOff: pen(100) }).expect(400);
    const dates = await post('coupons', {
      ...base,
      type: 'FREE_DELIVERY',
      endsAt: yesterday(),
      startsAt: nextWeek(),
    }).expect(400);
    expect(dates.body.details.fields.endsAt).toBeDefined();
    await post('coupons', { ...base, type: 'FREE_DELIVERY', storeId: 'st_nope' }).expect(400);
    await post('coupons', { ...base, code: 'con espacio', type: 'FREE_DELIVERY' }).expect(400);
  });

  it('editar: pasar a porcentaje con tope, y desactivarlo', async () => {
    const [id] = couponIds;
    await patch(`coupons/${id}`, { type: 'PERCENTAGE' }).expect(400);

    const pct = await patch(`coupons/${id}`, { type: 'PERCENTAGE', percentOff: 50, maxDiscount: pen(600) }).expect(200);
    expect(pct.body).toMatchObject({ type: 'PERCENTAGE', percentOff: 50, amountOff: null, maxDiscount: pen(600) });
    // 50% de S/ 30 = S/ 15, con tope de S/ 6.
    expect((await validate('POLLO4', 3000).expect(200)).body.discount).toEqual(pen(600));

    await patch(`coupons/${id}`, { isActive: false }).expect(200);
    expect((await validate('POLLO4', 3000).expect(422)).body.code).toBe('COUPON_INVALID');
  });

  it('un banner vigente aparece en el inicio con su negocio y cupón', async () => {
    const coupon = await post('coupons', {
      code: 'BANNER2',
      label: 'S/ 2 de regalo',
      type: 'FIXED_AMOUNT',
      amountOff: pen(200),
      startsAt: yesterday(),
      endsAt: nextWeek(),
    }).expect(201);
    couponIds.push(coupon.body.id);

    const res = await post('promotions', {
      cityId,
      storeId: STORE,
      couponId: coupon.body.id,
      title: 'Pollo con regalo',
      imageUrl: 'https://example.com/banner.jpg',
      startsAt: yesterday(),
      endsAt: nextWeek(),
    }).expect(201);
    promotionIds.push(res.body.id);

    const home = await http().get(`${API}/promotions`).expect(200);
    expect(home.body).toContainEqual({
      id: res.body.id,
      title: 'Pollo con regalo',
      subtitle: null,
      imageUrl: 'https://example.com/banner.jpg',
      storeId: STORE,
      couponCode: 'BANNER2',
    });

    await post('promotions', { ...res.body, id: undefined, couponId: 'cp_nope' }).expect(400);
  });

  it('un banner vencido o borrado sale del inicio', async () => {
    const [id] = promotionIds;
    await patch(`promotions/${id}`, {
      endsAt: yesterday(),
      startsAt: new Date(Date.now() - 2 * DAY).toISOString(),
    }).expect(200);
    let home = await http().get(`${API}/promotions`).expect(200);
    expect(home.body.map((p: { id: string }) => p.id)).not.toContain(id);

    const all = await http().get(`${API}/admin/promotions`).set(admin.auth).expect(200);
    expect(all.body.map((p: { id: string }) => p.id)).toContain(id);

    await http().delete(`${API}/admin/promotions/${id}`).set(admin.auth).expect(204);
    await http().delete(`${API}/admin/promotions/${id}`).set(admin.auth).expect(404);
    home = await http().get(`${API}/promotions`).expect(200);
    expect(home.body.map((p: { id: string }) => p.id)).not.toContain(id);
  });
});
