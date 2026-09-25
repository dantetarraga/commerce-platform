import { execSync } from 'node:child_process';
import { resolve } from 'node:path';
import { PrismaPg } from '@prisma/adapter-pg';
import { seed } from '../prisma/seed';
import { PrismaClient } from '../src/generated/prisma/client';
import { TEST_ENV } from './test-env';

/** Migra la base de test, la vacía y carga el seed. Solo toca bases `*_test`. */
export default async function globalSetup() {
  const dbName = new URL(TEST_ENV.DATABASE_URL).pathname.slice(1);
  if (!dbName.endsWith('_test')) throw new Error(`Los e2e solo corren contra una base *_test (recibí "${dbName}").`);

  execSync('npx prisma migrate deploy', { cwd: resolve(__dirname, '..'), env: process.env, stdio: 'pipe' });

  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: TEST_ENV.DATABASE_URL }) });
  try {
    const tables = await prisma.$queryRaw<{ tablename: string }[]>`
      SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
    const list = tables.map((t) => `"public"."${t.tablename}"`).join(', ');
    await prisma.$executeRawUnsafe(`TRUNCATE ${list} RESTART IDENTITY CASCADE`);
    await seed(prisma);
  } finally {
    await prisma.$disconnect();
  }
}
