# Chaski · backend

API REST de Chaski: NestJS 11 (monolito modular) + Prisma 7 + PostgreSQL 16.

El contrato lo define la app: los `Api*RemoteDataSource` y los datasources fake de
`mobile/lib/features/*/infrastructure` devuelven el mismo JSON que esta API.

## Requisitos

- Node 20.19+ (probado con 24).
- Docker, para el Postgres de desarrollo.

## Arranque

```bash
docker compose up -d            # desde la raíz del repo: Postgres en localhost:5433
cd backend
cp .env.example .env            # y cambia JWT_ACCESS_SECRET
npm install                     # también genera el cliente de Prisma
npm run db:deploy               # aplica las migraciones
npm run db:seed                 # Espinar con el catálogo de la demo
npm run start:dev               # http://localhost:3000/api/v1 · Swagger en /docs
```

La app se conecta con `USE_FAKE_DATA: false`:

- **Emulador de Android:** `mobile/env/dev.json` (host `10.0.2.2`).
- **Teléfono Android por USB:** `adb reverse tcp:3000 tcp:3000` y
  `mobile/env/dev-device.json` (`localhost`).
- **Simulador de iOS:** `mobile/env/dev-device.json`.

En debug, Android permite `http`; iOS lo permite solo hacia la red local.

### Entrar sin SMS

Todavía no hay proveedor de SMS: el código se escribe en el log. Fuera de
producción, con `OTP_DEV_CODE=123456` todos los códigos son ese valor.
El seed crea la cuenta demo `984123456` (Alex Quispe); cualquier otro celular
pide nombre y apellido.

## Scripts

| Script | Qué hace |
|---|---|
| `npm run start:dev` | API con recarga |
| `npm test` | unit tests |
| `npm run test:e2e` | e2e contra `chaski_test` (se migra, se vacía y se siembra en cada corrida) |
| `npm run lint` / `npm run typecheck` | ESLint + Prettier / TypeScript |
| `npm run db:migrate` | crea y aplica una migración nueva en desarrollo |
| `npm run db:seed` | siembra (idempotente, upsert por ID) |

## Estructura

```
src/
├── main.ts, app.module.ts, app.setup.ts   # bootstrap compartido con los e2e
├── config/env.ts                          # zod: si falta una variable, no arranca
├── database/                              # PrismaService (adapter pg)
├── common/                                # errores, validación, guards, utils puras
├── generated/prisma/                      # cliente generado (no se versiona)
└── modules/
    ├── auth/        # OTP por SMS, registro, refresh rotativo, guard JWT global
    ├── users/       # /users/me
    ├── cities/      # resolución de ciudad por ubicación
    ├── stores/      # listado con distancia/fee/ETA/horario, detalle, menú
    ├── products/    # detalle con variantes y opciones
    ├── search/      # /search y /discovery/* (unaccent + pg_trgm)
    ├── coupons/     # validación compartida por la bolsa y el pedido
    ├── orders/      # crear, listar, detalle, calificar (precios en order-pricing.ts)
    ├── categories/, promotions/, health/
    └── delivery/    # cálculo puro de distancia, cobertura, fee y ETA
```

## Endpoints

Prefijo `/api/v1`. Errores siempre como
`{ statusCode, code, message, details?, requestId }`, con `message` en español
(la app lo muestra tal cual). Los de validación traen `details.fields`.

| Método | Ruta | Auth |
|---|---|---|
| POST | `/auth/otp/request` `{ phone }` → `{ phone, resendAfterSeconds, codeLength }` | pública |
| POST | `/auth/otp/verify` `{ phone, code }` → `AUTHENTICATED` + sesión, o `PROFILE_REQUIRED` + `registrationToken` | pública |
| POST | `/auth/register` `{ registrationToken, firstName, lastName }` → sesión | pública |
| POST | `/auth/refresh` `{ refreshToken }` → par nuevo (rotación) | pública |
| POST | `/auth/logout` `{ refreshToken }` → 204, idempotente | pública |
| GET/PATCH | `/users/me` | Bearer |
| GET | `/cities`, `/categories`, `/promotions?cityId=` | pública |
| GET | `/stores?lat=&lng=&sort=distance\|popular\|rating&categoryId=&includeOutOfCoverage=&page=&limit=` | pública |
| GET | `/stores/:id?lat=&lng=`, `/stores/:id/products` | pública |
| GET | `/products/:id?lat=&lng=` | pública |
| GET | `/search?q=&lat=&lng=` | pública |
| GET | `/discovery/local-products`, `/discovery/popular-searches` | pública |
| POST | `/coupons/validate` `{ code, storeId, subtotal }` → `{ code, discount, label }` | Bearer |
| POST | `/orders` (header opcional `Idempotency-Key`) → pedido | Bearer (CUSTOMER) |
| GET | `/orders?cursor=&limit=` → `{ items, nextCursor }`, `/orders/:id` | Bearer (CUSTOMER) |
| POST | `/orders/:id/rating` `{ rating: 1..5, comment? }` | Bearer (CUSTOMER) |
| GET | `/health` | pública |

`POST /orders` recibe la bolsa del dispositivo y recalcula todo: horario (o
`scheduledFor` hasta 7 días), cobertura, variantes y opciones, stock
condicional, mínimo, cupón (con cupo condicional), propina (máx. S/ 50) y
vuelto. Todo en una transacción; el código público sale de `order_code_seq`.
