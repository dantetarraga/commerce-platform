/**
 * Arranque de producción: crea (o promueve) al primer admin y la fila de la
 * comisión, sin datos de demo. Lo demás (ciudades, negocios, repartidores) se
 * carga desde el panel.
 *
 *   ADMIN_PHONE=987654321 ADMIN_FIRST_NAME=Rosa ADMIN_LAST_NAME=Quispe \
 *   DATABASE_URL="<URL pública de Postgres>" npm run db:bootstrap
 */
import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, Role } from '../src/generated/prisma/client';

export async function bootstrapAdmin(
  prisma: PrismaClient,
  admin: { phone: string; firstName: string; lastName: string },
): Promise<string> {
  if (!/^9\d{8}$/.test(admin.phone)) throw new Error('ADMIN_PHONE debe ser un celular de 9 dígitos que empiece con 9.');
  if (!admin.firstName.trim()) throw new Error('Falta ADMIN_FIRST_NAME.');

  const user = await prisma.user.upsert({
    where: { phone: admin.phone },
    create: { phone: admin.phone, firstName: admin.firstName.trim(), lastName: admin.lastName.trim() },
    update: {},
  });
  for (const role of [Role.CUSTOMER, Role.ADMIN]) {
    await prisma.userRole.upsert({
      where: { userId_role: { userId: user.id, role } },
      create: { userId: user.id, role },
      update: {},
    });
  }
  // La migración ya la crea; esto cubre una base restaurada sin ella.
  await prisma.platformSettings.upsert({ where: { id: 1 }, create: { commissionRateBps: 1000 }, update: {} });
  return user.id;
}

if (require.main === module) {
  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });
  bootstrapAdmin(prisma, {
    phone: process.env.ADMIN_PHONE ?? '',
    firstName: process.env.ADMIN_FIRST_NAME ?? '',
    lastName: process.env.ADMIN_LAST_NAME ?? '',
  })
    .then((id) => console.log(`Admin listo (${id}). Entra al panel con ese celular.`))
    .catch((error: unknown) => {
      console.error(error instanceof Error ? error.message : error);
      process.exitCode = 1;
    })
    .finally(() => void prisma.$disconnect());
}
