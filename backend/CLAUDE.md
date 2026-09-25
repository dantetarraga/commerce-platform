# Backend (NestJS 11 + Prisma 7 + PostgreSQL)

## El contrato lo define la app

Los endpoints y el JSON salen de `mobile/lib/features/*/infrastructure` (datasources `Api*` y `Fake*`, que devuelven lo mismo), no de un diseño aparte. Antes de crear o cambiar un endpoint, lee el datasource y el fake: nombres de campos, forma de `{ amount, currency }`, códigos de error y mensajes.

## Convenciones (prevalecen sobre las skills de NestJS)

- **Controller → Service → Prisma.** Sin capa de repositorios encima de Prisma (la skill `nestjs-best-practices` recomienda repositorios: aquí no). El SQL crudo va en `*.queries.ts` del módulo con `Prisma.sql`.
- **Prisma 7**: cliente generado en `src/generated/prisma` (CommonJS), `PrismaService` con `@prisma/adapter-pg`, URL en `prisma.config.ts`. Nunca TypeORM.
- **Auth propia**: `JwtAuthGuard` global + `@Public()` y `RolesGuard` + `@Roles()`. Sin Passport. Login por celular + OTP.
- **Errores**: `throw new AppException(ErrorCode.X, HttpStatus.Y, 'Mensaje en español.', details?)`. El código nuevo va a `ErrorCode`. El filtro global da `{ statusCode, code, message, details?, requestId }`; la validación sale como `VALIDATION_ERROR` con `details.fields`.
- **Dinero en céntimos (Int)**; en la API `{ amount, currency }` con `money()`.
- **Proyecciones puras** de BD → JSON (p. ej. `stores/store-presenter.ts`); la lógica de cálculo (delivery, horarios) en funciones puras con unit tests.
- **Config** solo vía `ConfigService<Env, true>`; variables nuevas en `src/config/env.ts` (zod) y `.env.example`.
- **Estructura**: módulos planos; si pasan de ~10 archivos, se agrupan por responsabilidad (`auth/otp/`, `auth/tokens/`), no por tipo. Unit tests `*.spec.ts` junto al archivo; e2e en `test/`.

## Comandos

```bash
docker compose up -d        # desde la raíz: Postgres en localhost:5433
npm run start:dev
npm test                    # unit
npm run test:e2e            # contra chaski_test (migrate deploy + truncate + seed)
npm run lint && npm run typecheck
npm run db:migrate          # nueva migración en desarrollo
```

Node 20.19+ (en esta máquina, `nvm use 24.21.0`). No usar `prisma migrate reset`: Prisma 7 lo bloquea para agentes.
