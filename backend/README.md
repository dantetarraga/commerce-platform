# Apamuy · backend

API REST de Apamuy: NestJS 11 (monolito modular) + Prisma 7 + PostgreSQL 16.

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

### Push

`PUSH_PROVIDER=log` (por defecto) escribe los avisos en el log. Para enviarlos de verdad: `PUSH_PROVIDER=fcm` y `FCM_SERVICE_ACCOUNT_BASE64` con la cuenta de servicio de Firebase en base64 (`base64 -w0 cuenta.json`). La app registra el teléfono en `PUT /users/me/devices`; ver `mobile/README.md`.

### Fotos en Cloudflare R2

`STORAGE_PROVIDER=none` (por defecto) apaga la subida: el panel deja pegar una URL. Con `r2`, el panel y el Portal Socios piden a `POST /uploads/images` una URL firmada (5 minutos, con tipo y tamaño fijos) y suben la foto directo al bucket. La API no recibe el archivo. Después se guarda la `publicUrl` en el producto, negocio o banner.

1. En Cloudflare, **R2 → Create bucket** (`apamuy-images`).
2. **Settings → Public access → Custom domain**: un subdominio propio (`img.apamuy.pe`). Mientras no haya dominio sirve el `r2.dev` de desarrollo, que tiene límite de tráfico.
3. **Settings → CORS policy**, para que el navegador pueda hacer el `PUT`:

   ```json
   [{ "AllowedOrigins": ["https://panel.apamuy.pe", "http://localhost:5173"],
      "AllowedMethods": ["PUT"],
      "AllowedHeaders": ["content-type", "cache-control"],
      "MaxAgeSeconds": 3600 }]
   ```

4. **R2 → Manage API tokens → Create API token**: permiso *Object Read & Write* solo sobre ese bucket.
5. Variables: `R2_ACCOUNT_ID` (en la portada de R2), `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` y `R2_PUBLIC_URL` (`https://img.apamuy.pe`).

Cada foto tiene una key nueva (`stores/<id>/products/<uuid>.webp`) y se sirve con `Cache-Control: immutable`. Cambiar la foto no borra la anterior; la limpieza está en `docs/PENDIENTES.md`.

### Entrar sin SMS

En desarrollo `SMS_PROVIDER=log`: el código se escribe en el log, y con
`OTP_DEV_CODE=123456` todos los códigos son ese valor. En producción el
envío es por Twilio (obligatorio) y `OTP_DEV_CODE` está prohibido.
El seed crea la cuenta demo `984123456` (Alex Quispe); cualquier otro celular
pide nombre y apellido.

## Scripts

| Script | Qué hace |
|---|---|
| `npm run start:dev` | API con recarga |
| `npm test` | unit tests |
| `npm run test:e2e` | e2e contra `apamuy_test` (se migra, se vacía y se siembra en cada corrida) |
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
    ├── addresses/   # libreta sincronizada con la app (local primero)
    ├── cities/      # resolución de ciudad por ubicación
    ├── stores/      # listado con distancia/fee/ETA/horario, detalle, menú
    ├── products/    # detalle con variantes y opciones
    ├── search/      # /search y /discovery/* (unaccent + pg_trgm)
    ├── coupons/     # validación compartida por la bolsa y el pedido
    ├── orders/      # crear, listar, detalle, calificar, cancelar; status/ = máquina de estados
    ├── merchant/    # operación del negocio: /merchant/*
    ├── couriers/    # operación del repartidor: /courier/*
    ├── notifications/ # avisos in-app, creados en la transacción de cada cambio de estado
    ├── maintenance/ # limpieza diaria de datos de auth vencidos
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
| GET/PUT | `/users/me/addresses` `{ selectedId, addresses[] }` (libreta completa, ids de la app) | Bearer |
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
| POST | `/orders/:id/cancel` `{ reason? }` (solo en RECEIVED o CONFIRMED) | Bearer (CUSTOMER) |
| GET | `/merchant/orders?status=&cursor=`, `/merchant/orders/:id` (con cliente y ubicación) | Bearer (MERCHANT, ADMIN) |
| POST | `/merchant/orders/:id/status` `{ status: CONFIRMED\|PREPARING\|READY }`, `/merchant/orders/:id/cancel` `{ reason }` | Bearer (MERCHANT, ADMIN) |
| PATCH | `/merchant/stores/:id` `{ isAcceptingOrders }` | Bearer (MERCHANT, ADMIN) |
| GET | `/courier/orders/available`, `/courier/orders` | Bearer (COURIER) |
| POST | `/courier/orders/:id/accept`, `/courier/orders/:id/status` `{ status: ON_THE_WAY\|DELIVERED }` | Bearer (COURIER) |
| POST | `/uploads/images` `{ purpose, storeId?, contentType, size }` → `{ uploadUrl, headers, publicUrl }` (503 `STORAGE_NOT_CONFIGURED` sin R2) | Bearer (MERCHANT, ADMIN) |
| POST | `/merchant/catalog/stores/:id/products/import` y `/admin/stores/:id/products/import` `{ rows, dryRun? }` → resumen por fila | Bearer (MERCHANT, ADMIN) |
| GET | `/notifications?cursor=&limit=` → `{ items, nextCursor, unreadCount }`; POST `/notifications/read-all` | Bearer |
| GET | `/health` | pública |

`POST /orders` recibe la bolsa del dispositivo y recalcula todo: horario (o
`scheduledFor` hasta 7 días), cobertura, variantes y opciones, stock
condicional, mínimo, cupón (con cupo condicional), propina (máx. S/ 50) y
vuelto. Todo en una transacción; el código público sale de `order_code_seq`.

### Operar un pedido (sin panel todavía)

Los estados avanzan con la máquina de `orders/status/order-status.machine.ts`:
el negocio confirma, prepara y marca listo; un repartidor lo toma (solo uno
puede), sale y entrega. Entregar marca el pago como cobrado; cancelar devuelve
stock y cupón. Para probarlo desde Swagger (`/docs`), entra con los usuarios
del seed (código `123456`):

| Rol | Celular |
|---|---|
| Cliente demo | `984123456` |
| Dueño de Pollería El Chaski Dorado | `910000000` (los demás negocios: `910000001`…`910000010`, en el orden del catálogo) |
| Repartidores | `900000101` (Luis), `900000102` (Yeni) |
| Admin | `900000001` |

## Despliegue en Railway

La infraestructura está en `.railway/railway.ts` (Infrastructure as Code de
Railway): el servicio `api` (este `Dockerfile`, migraciones en el pre-deploy,
health check en `/api/v1/health`), la base `postgres` y las variables. Railway
retiró `railway.toml` para servicios nuevos.

1. **CLI:** `npm i -g @railway/cli` (5.42.1 o más nueva) y `railway login`.
   En Railway, dale acceso a GitHub al repo `dantetarraga/commerce-platform`.
2. **Proyecto:** crea un proyecto vacío en Railway y, desde la raíz del repo,
   `railway link`.
3. **Aplicar:** en `.railway/`, `npm install`; luego `railway config plan`
   para ver los cambios y `railway config apply` para crearlos.
4. **Secretos:** el archivo los declara con `preserve()`, así que se cargan
   una vez en *Variables* del servicio `api` y se conservan en cada apply:

   | Variable | Valor |
   |---|---|
   | `JWT_ACCESS_SECRET`, `OTP_SECRET` | dos valores distintos de 48+ caracteres: `node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"` |
   | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` | de la consola de Twilio |
   | `TWILIO_MESSAGING_SERVICE_SID` | el Messaging Service (`MG…`) |
   | `FCM_SERVICE_ACCOUNT_BASE64` | la cuenta de servicio de Firebase en base64 |
   | `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_URL` | del bucket de fotos (ver "Fotos en Cloudflare R2") |

   Railway pone `PORT` solo. Si falta o está mal una variable, la API no
   arranca y el log dice cuál. Una variable nueva se agrega también en
   `railway.ts`: lo que no está en el archivo, el apply lo borra.
5. **Dominio:** *Settings → Networking → Generate Domain* (el dominio de
   Railway no se declara en `railway.ts`). Revisa
   `https://<dominio>/api/v1/health`.
6. **Primer admin:** desde tu máquina, contra la URL pública de la base:
   `ADMIN_PHONE=9XXXXXXXX ADMIN_FIRST_NAME=Nombre ADMIN_LAST_NAME=Apellido DATABASE_URL="<URL pública de Postgres>" npm run db:bootstrap`.
   Con ese celular entras al panel y das de alta la ciudad, los negocios y
   los repartidores. **No corras `db:seed` en producción**: trae usuarios con
   celulares de prueba (900000001 es admin) y cupones de demo; por eso se
   niega con una base que no sea local (`SEED_ALLOW_REMOTE=true` solo para
   un staging desechable).
7. **App:** un `env/prod.json` con `USE_FAKE_DATA: false` y
   `API_BASE_URL: https://<dominio>/api/v1`.

**Twilio:** una cuenta de prueba solo envía a números verificados en la
consola. Para usuarios reales hace falta pasar la cuenta a pago y crear un
Messaging Service con un remitente que entregue en Perú.

**Pendiente:** la imagen pesa ~800 MB porque incluye el CLI de Prisma para
migrar; se puede separar en una imagen solo de migraciones más adelante.
