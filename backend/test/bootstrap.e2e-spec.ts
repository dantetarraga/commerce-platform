import type { INestApplication } from '@nestjs/common';
import { bootstrapAdmin } from '../prisma/bootstrap-admin';
import { seedAllowed } from '../prisma/seed';
import { PrismaService } from '../src/database/prisma.service';
import { Role } from '../src/generated/prisma/enums';
import { createTestApp } from './test-app';

describe('Arranque de producción (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const phone = '977000111';

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { phone } });
    await app.close();
  });

  it('el seed de demo solo corre contra una base local', () => {
    expect(seedAllowed('postgresql://apamuy:apamuy@localhost:5433/apamuy')).toBe(true);
    expect(seedAllowed('postgresql://u:p@monorail.proxy.rlwy.net:41234/railway')).toBe(false);
    expect(seedAllowed('postgresql://u:p@monorail.proxy.rlwy.net:41234/railway', 'true')).toBe(true);
    expect(seedAllowed(undefined)).toBe(false);
  });

  it('crea el primer admin y es idempotente', async () => {
    const id = await bootstrapAdmin(prisma, { phone, firstName: ' Rosa ', lastName: 'Quispe' });
    expect(await bootstrapAdmin(prisma, { phone, firstName: 'Otra', lastName: 'Persona' })).toBe(id);

    const user = await prisma.user.findUniqueOrThrow({ where: { id }, include: { roles: true } });
    expect(user.firstName).toBe('Rosa');
    expect(user.roles.map((r) => r.role).sort()).toEqual([Role.ADMIN, Role.CUSTOMER].sort());
    await expect(bootstrapAdmin(prisma, { phone: '12345', firstName: 'X', lastName: '' })).rejects.toThrow(/9 dígitos/);
  });
});
