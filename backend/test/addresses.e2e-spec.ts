import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, signUp, TestSession } from './helpers';
import { createTestApp } from './test-app';

const casa = {
  id: 'adr_1',
  kind: 'HOME',
  label: null,
  street: 'Jr. Túpac Amaru 214',
  reference: 'Puerta verde',
  latitude: -14.7936,
  longitude: -71.4128,
};
const trabajo = { ...casa, id: 'adr_2', kind: 'WORK', street: 'Av. Espinar 100', reference: '' };
// ~11 km al norte de la plaza: fuera de los 6 km de la zona de reparto.
const lejos = { ...casa, id: 'adr_lejos', latitude: -14.6936 };

describe('Direcciones (e2e)', () => {
  let app: INestApplication<App>;
  let ana: TestSession;
  let beto: TestSession;
  const http = () => request(app.getHttpServer());
  const put = (session: TestSession, body: object) =>
    http().put(`${API}/users/me/addresses`).set(session.auth).send(body);

  beforeAll(async () => {
    app = await createTestApp();
    ana = await signUp(app, '963000001');
    beto = await signUp(app, '963000002');
  });

  afterAll(async () => {
    await app.close();
  });

  it('empieza vacía y guarda la libreta con la seleccionada', async () => {
    await http().get(`${API}/users/me/addresses`).set(ana.auth).expect(200, { selectedId: null, addresses: [] });

    const saved = await put(ana, { selectedId: 'adr_2', addresses: [casa, trabajo] }).expect(200);
    expect(saved.body).toEqual({ selectedId: 'adr_2', addresses: [casa, trabajo] });
  });

  it('reemplazar actualiza, archiva las que faltan y corrige una seleccionada inexistente', async () => {
    const edited = { ...casa, street: 'Jr. Túpac Amaru 216' };
    const res = await put(ana, { selectedId: 'adr_2', addresses: [edited] }).expect(200);
    // adr_2 ya no está: queda seleccionada la primera.
    expect(res.body).toEqual({ selectedId: 'adr_1', addresses: [edited] });
  });

  it('el mismo id de la app en otra cuenta es otra dirección', async () => {
    await put(beto, { selectedId: 'adr_1', addresses: [{ ...casa, street: 'Calle de Beto 1' }] }).expect(200);
    const anas = await http().get(`${API}/users/me/addresses`).set(ana.auth).expect(200);
    expect(anas.body.addresses[0].street).toBe('Jr. Túpac Amaru 216');
  });

  it('valida la libreta', async () => {
    const tooMany = Array.from({ length: 11 }, (_, i) => ({ ...casa, id: `adr_${i}` }));
    await put(ana, { addresses: tooMany }).expect(400);
    await put(ana, { addresses: [casa, casa] }).expect(400);
    const bad = await put(ana, { addresses: [{ ...casa, street: 'x', kind: 'CASA' }] }).expect(400);
    expect(Object.keys(bad.body.details.fields).sort()).toEqual(['addresses.0.kind', 'addresses.0.street']);
  });

  it('rechaza una dirección nueva fuera de la zona de reparto y guarda la ciudad de las demás', async () => {
    const res = await put(ana, { addresses: [casa, lejos] }).expect(422);
    expect(res.body.code).toBe('ADDRESS_OUT_OF_COVERAGE');
    expect(res.body.details).toEqual({ ids: ['adr_lejos'] });

    await put(ana, { addresses: [casa] }).expect(200);
    const prisma = app.get(PrismaService);
    const saved = await prisma.address.findFirstOrThrow({ where: { clientId: 'adr_1', user: { phone: '963000001' } } });
    expect(saved.cityId).toBe('city_espinar');
  });

  it('no traba la sincronización por una dirección vieja fuera de la zona', async () => {
    const prisma = app.get(PrismaService);
    const user = await prisma.user.findFirstOrThrow({ where: { phone: '963000002' } });
    await prisma.address.create({
      data: {
        userId: user.id,
        clientId: lejos.id,
        kind: 'HOME',
        street: lejos.street,
        latitude: lejos.latitude,
        longitude: lejos.longitude,
      },
    });
    await put(beto, { addresses: [lejos, { ...casa, id: 'adr_9' }] }).expect(200);
    // Pero no se puede mover a otro punto fuera de la zona.
    await put(beto, { addresses: [{ ...lejos, latitude: -14.6 }] }).expect(422);
  });

  it('exige sesión', async () => {
    await http().get(`${API}/users/me/addresses`).expect(401);
  });
});
