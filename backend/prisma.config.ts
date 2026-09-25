import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  // Sin `env()`: `prisma generate` (postinstall) debe funcionar aunque aún no
  // exista .env; migrate y seed fallan con un mensaje claro si falta la URL.
  datasource: {
    url: process.env.DATABASE_URL,
  },
});
