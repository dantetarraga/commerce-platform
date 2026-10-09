import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { PrismaService } from '../src/database/prisma.service';
import { API, sessionFor, TestSession } from './helpers';
import { createTestApp } from './test-app';

const ADMIN = '900000001';
const CUSTOMER = '913000001'; // solo lo usa este e2e
const COURIER = '913000002';

describe('Admin: usuarios y métricas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let admin: TestSession;
  let customerId: string;
  let courierId: string;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await sessionFor(app, ADMIN);
    const cityId = (await prisma.city.findFirstOrThrow()).id;
    customerId = (
      await prisma.user.create({
        data: { phone: CUSTOMER, firstName: 'Marta', lastName: 'Ccama', roles: { create: { role: 'CUSTOMER' } } },
      })
    ).id;
    courierId = (
      await prisma.user.create({
        data: {
          phone: COURIER,
          firstName: 'Teo',
          lastName: 'Huillca',
          roles: { create: [{ role: 'CUSTOMER' }] },
          courier: { create: { cityId, vehicleType: 'MOTO', vehicleLabel: 'Moto azul' } },
        },
      })
    ).id;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { phone: { in: [CUSTOMER, COURIER] } } });
    await app.close();
  });

  it('solo el admin entra', async () => {
    const customer = await sessionFor(app, CUSTOMER);
    await http().get(`${API}/admin/users`).set(customer.auth).expect(403);
    await http()
      .get(`${API}/admin/analytics`)
      .query({ from: '2026-10-01', to: '2026-10-07' })
      .set(customer.auth)
      .expect(403);
  });

  it('lista con búsqueda por nombre o celular y filtro por rol', async () => {
    const byName = await http().get(`${API}/admin/users`).query({ q: 'marta cca' }).set(admin.auth).expect(200);
    expect(byName.body.items.map((u: { id: string }) => u.id)).toEqual([customerId]);
    expect(byName.body).toMatchObject({ page: 1, total: 1 });
    expect(byName.body.items[0]).toMatchObject({ phone: CUSTOMER, roles: ['CUSTOMER'], orders: 0, isActive: true });

    const byPhone = await http().get(`${API}/admin/users`).query({ q: '913000' }).set(admin.auth).expect(200);
    expect(byPhone.body.total).toBe(2);

    const admins = await http().get(`${API}/admin/users`).query({ role: 'ADMIN' }).set(admin.auth).expect(200);
    expect(admins.body.items.every((u: { roles: string[] }) => u.roles.includes('ADMIN'))).toBe(true);
    const customers = await http()
      .get(`${API}/admin/users`)
      .query({ role: 'CUSTOMER', q: '913000' })
      .set(admin.auth)
      .expect(200);
    // Teo tiene vehículo pero no el rol (como un repartidor suspendido): cuenta como cliente.
    expect(customers.body.total).toBe(2);

    await http().get(`${API}/admin/users`).query({ role: 'JEFE' }).set(admin.auth).expect(400);
  });

  it('bloquear cierra sus sesiones y no lo deja entrar; desbloquear lo devuelve', async () => {
    const customer = await sessionFor(app, CUSTOMER);
    const blocked = await http()
      .post(`${API}/admin/users/${customerId}/block`)
      .set(admin.auth)
      .send({ reason: 'Pedidos falsos' })
      .expect(200);
    expect(blocked.body).toMatchObject({ isActive: false, activeSessions: 0 });
    expect(blocked.body.history[0]).toMatchObject({ action: 'BLOCKED', details: { reason: 'Pedidos falsos' } });
    await http().post(`${API}/auth/refresh`).send({ refreshToken: customer.refreshToken }).expect(401);

    const list = await http()
      .get(`${API}/admin/users`)
      .query({ status: 'blocked', q: 'marta' })
      .set(admin.auth)
      .expect(200);
    expect(list.body.total).toBe(1);

    const unblocked = await http().post(`${API}/admin/users/${customerId}/unblock`).set(admin.auth).expect(200);
    expect(unblocked.body.isActive).toBe(true);
    expect(unblocked.body.history.map((h: { action: string }) => h.action)).toEqual(['UNBLOCKED', 'BLOCKED']);
  });

  it('el admin no se bloquea ni se quita el acceso a sí mismo', async () => {
    const me = admin.user.id;
    await http().post(`${API}/admin/users/${me}/block`).set(admin.auth).send({}).expect(409);
    await http().put(`${API}/admin/users/${me}/admin`).set(admin.auth).send({ isAdmin: false }).expect(409);
  });

  it('suspender y reactivar a un repartidor queda en su historial', async () => {
    await http()
      .post(`${API}/admin/users/${courierId}/restore-partner`)
      .set(admin.auth)
      .send({ roles: ['COURIER'] })
      .expect(200);
    await http()
      .post(`${API}/admin/users/${courierId}/suspend-partner`)
      .set(admin.auth)
      .send({ roles: ['COURIER'] })
      .expect(200);
    const restored = await http()
      .post(`${API}/admin/users/${courierId}/restore-partner`)
      .set(admin.auth)
      .send({ roles: ['COURIER'] })
      .expect(200);
    expect(restored.body.roles).toContain('COURIER');
    expect(restored.body.performance.courier).toMatchObject({
      deliveries: 0,
      collected: { amount: 0, currency: 'PEN' },
    });
    expect(restored.body.history.map((h: { action: string }) => h.action).slice(0, 3)).toEqual([
      'PARTNER_RESTORED',
      'PARTNER_SUSPENDED',
      'PARTNER_RESTORED',
    ]);
    expect(restored.body.history[0].by).toBeTruthy();

    // Sin vehículo no se puede devolver el rol de repartidor.
    await http()
      .post(`${API}/admin/users/${customerId}/restore-partner`)
      .set(admin.auth)
      .send({ roles: ['COURIER'] })
      .expect(409);
  });

  it('dar y quitar el acceso de admin', async () => {
    const granted = await http()
      .put(`${API}/admin/users/${customerId}/admin`)
      .set(admin.auth)
      .send({ isAdmin: true })
      .expect(200);
    expect(granted.body.roles).toContain('ADMIN');
    const revoked = await http()
      .put(`${API}/admin/users/${customerId}/admin`)
      .set(admin.auth)
      .send({ isAdmin: false })
      .expect(200);
    expect(revoked.body.roles).not.toContain('ADMIN');
  });

  it('el detalle trae sus pedidos y estadísticas', async () => {
    const res = await http().get(`${API}/admin/users/${customerId}`).set(admin.auth).expect(200);
    expect(res.body.stats).toMatchObject({ orders: 0, spent: { amount: 0, currency: 'PEN' } });
    expect(res.body.recentOrders).toEqual([]);
    await http().get(`${API}/admin/users/usr_nope`).set(admin.auth).expect(404);
  });

  it('métricas del rango con su periodo anterior', async () => {
    const res = await http()
      .get(`${API}/admin/analytics`)
      .query({ from: '2026-01-01', to: '2026-01-07' })
      .set(admin.auth)
      .expect(200);
    expect(res.body).toMatchObject({ previousFrom: '2025-12-25', previousTo: '2025-12-31' });
    expect(res.body.byDay).toHaveLength(7);
    expect(res.body.byHour).toHaveLength(24);
    expect(res.body.kpis.gmv).toEqual({ amount: expect.any(Number), currency: 'PEN' });
    await http()
      .get(`${API}/admin/analytics`)
      .query({ from: '2026-01-01', to: '2026-12-31' })
      .set(admin.auth)
      .expect(400);
  });
});
