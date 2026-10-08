# Apamuy — Arquitectura y diseño inicial

Versión 0.5 · 2026-09-24 · Estado: **en implementación** · [Cambios v0.4 → v0.5](#cambios-v04--v05) · [Cambios v0.3 → v0.4](#cambios-v03--v04) · [Cambios v0.2 → v0.3](#cambios-v02--v03) · [Cambios v0.1 → v0.2](#cambios-v01--v02)

---

## 1. Arquitectura general

```
┌──────────────────────────┐        HTTPS / REST (JSON)          ┌───────────────────────────────────────┐
│  Flutter App (CUSTOMER)  │ ──────────────────────────────────▶ │  NestJS API · monolito modular        │
│  Clean Architecture      │                                     │                                       │
│  Riverpod · GoRouter     │ ◀────── WebSocket (Socket.IO) ───── │  Controllers → Services → Prisma      │
│  Dio · secure_storage    │         order.updated               │  Guards · Pipes · Filters · Gateways  │
└──────────────────────────┘                                     │  EventEmitter (eventos internos)      │
        │                                                        └───────────────┬───────────────────────┘
        │ SDK (detrás de una abstracción)                                        │
        ▼                                                                        ▼
  Google Maps / Mapbox                                            PostgreSQL 16 (Prisma, pg_trgm, unaccent)
                                                                                 │
                                                            (Fase 3+) FCM push · (Fase 4) Culqi/MP/Niubiz
```

**Principios**

- **Monolito modular** en NestJS: un solo deploy, módulos por capacidad de negocio con fronteras claras. Los módulos se comunican llamando servicios exportados o, para efectos secundarios (notificaciones, WebSocket), mediante **eventos internos** (`@nestjs/event-emitter`). Así, si algún día hace falta separar algo, ya está desacoplado. No se hacen microservicios.
- **El backend es la fuente de verdad** de precios, disponibilidad, delivery fee, descuentos, impuestos y totales. Flutter solo *muestra* lo que el backend calcula (`POST /checkout/quote`).
- **Flutter con Clean Architecture por feature** con nomenclatura DDD (domain / infrastructure / presentation). El dominio es Dart puro.
- **Multi-ciudad desde el modelo de datos**: `City` es una entidad de primer nivel (zona horaria, moneda, tarifas y parámetros de delivery). Stores, couriers, cupones y promociones pertenecen a una ciudad.
- **Repo único (monorepo)**: `backend/`, `mobile/`, `docs/` y `docker-compose.yml` en la raíz.

---

## 2. Estructura del frontend Flutter (`mobile/`)

```
mobile/
├── pubspec.yaml
├── analysis_options.yaml            # very_good_analysis / lints estrictos
├── build.yaml                       # config de freezed / json_serializable / riverpod_generator
├── env/
│   ├── dev.json                     # --dart-define-from-file=env/dev.json
│   └── prod.json
├── assets/ (images, icons, fonts, lottie)
├── test/                            # espejo de lib/
│   ├── features/…
│   ├── core/…
│   └── helpers/ (mocks con mocktail, fixtures, pump_app.dart, provider_container.dart)
└── lib/
    ├── main.dart                    # bootstrap: ProviderScope + env
    ├── app/
    │   ├── app.dart                 # MaterialApp.router
    │   ├── config/
    │   │   ├── env.dart             # AppEnv (baseUrl, wsUrl, mapsKey) desde dart-define
    │   │   └── app_config_provider.dart
    │   ├── router/
    │   │   ├── app_router.dart      # GoRouter + redirect según AuthState
    │   │   ├── routes.dart          # paths; cada página expone además `static const name` para goNamed
    │   │   └── scaffold_with_nav.dart  # StatefulShellRoute (Home, Buscar, Pedidos, Perfil)
    │   └── theme/
    │       ├── app_theme.dart
    │       ├── app_colors.dart
    │       ├── app_typography.dart
    │       └── app_spacing.dart
    │
    ├── core/
    │   ├── network/
    │   │   ├── dio_client.dart               # instancia principal de Dio
    │   │   ├── interceptors/
    │   │   │   ├── auth_interceptor.dart     # Bearer + refresh con cola (QueuedInterceptor)
    │   │   │   ├── request_id_interceptor.dart
    │   │   │   └── logging_interceptor.dart  # solo en dev
    │   │   ├── api_error_mapper.dart         # DioException → Failure
    │   │   ├── api_error_dto.dart            # { statusCode, code, message, details, requestId }
    │   │   └── paginated_response.dart       # PageResponse (offset) y CursorResponse
    │   ├── realtime/
    │   │   ├── realtime_client.dart          # contrato abstracto
    │   │   └── socket_io_realtime_client.dart
    │   ├── maps/
    │   │   ├── map_view.dart                 # widget abstracto AppMapView
    │   │   ├── google_map_view.dart          # implementación concreta
    │   │   ├── location_service.dart         # contrato (permisos + posición actual)
    │   │   ├── geolocator_location_service.dart
    │   │   ├── geocoding_service.dart        # contrato (coordenadas ↔ dirección legible)
    │   │   └── geo_point.dart
    │   ├── storage/
    │   │   ├── secure_token_storage.dart     # flutter_secure_storage
    │   │   └── preferences_storage.dart      # shared_preferences (onboarding visto, etc.)
    │   ├── errors/
    │   │   ├── failure.dart                  # sealed class Failure
    │   │   └── app_exception.dart            # excepciones internas de la capa infrastructure
    │   ├── result/
    │   │   └── result.dart                   # sealed Result<T> = Success | Error(Failure)
    │   ├── domain/                           # value objects compartidos entre features
    │   │   ├── money.dart                    # Money (céntimos + moneda, suma/multiplicación seguras)
    │   │   ├── email_address.dart
    │   │   ├── phone_number.dart
    │   │   ├── geo_coordinates.dart          # lat/lng validados (el GeoPoint de maps los usa)
    │   │   └── value_failure.dart            # errores de validación de value objects
    │   ├── constants/
    │   └── utils/ (formatters, debouncer, validators)
    │
    ├── features/
    │   ├── auth/
    │   │   ├── auth.dart            # barrel: API pública del feature (providers, entidades, widgets reutilizables)
    │   │   ├── domain/
    │   │   │   ├── entities/ (user_session.dart, auth_user.dart)
    │   │   │   ├── value_objects/ (password.dart, person_name.dart)   # solo los propios del feature
    │   │   │   ├── repositories/auth_repository.dart
    │   │   │   └── usecases/ (login.dart, register.dart, logout.dart, restore_session.dart)
    │   │   ├── infrastructure/
    │   │   │   ├── datasources/
    │   │   │   │   ├── remote/auth_remote_data_source.dart
    │   │   │   │   └── local/auth_local_data_source.dart   # tokens en secure storage
    │   │   │   ├── models/ (login_request_dto.dart, auth_response_dto.dart)   # subcarpeta por fuente si hay APIs externas (models/culqi/…)
    │   │   │   ├── mappers/auth_mapper.dart
    │   │   │   └── repositories/auth_repository_impl.dart
    │   │   └── presentation/
    │   │       ├── pages/ (splash_page.dart, onboarding_page.dart, login_page.dart, register_page.dart)
    │   │       ├── widgets/ (auth_form_field.dart, password_field.dart)
    │   │       ├── providers/ (auth_controller.dart, auth_providers.dart)
    │   │       └── state/ (auth_state.dart, login_form_state.dart)
    │   │
    │   ├── home/            # SOLO presentation: compone los providers públicos de stores,
    │   │   │                # orders, addresses y promotions. No tiene domain ni infrastructure propios.
    │   │   └── presentation/
    │   │       ├── pages/home_page.dart
    │   │       └── widgets/ (home_app_bar.dart, search_entry.dart, categories_carousel.dart,
    │   │                     popular_stores_section.dart, nearby_stores_section.dart,
    │   │                     promotions_banner.dart, recent_orders_section.dart, home_skeleton.dart)
    │   │
    │   ├── promotions/      # banners del Home (entidad Promotion + repositorio)
    │   ├── search/          # búsqueda unificada de negocios y productos (debounce)
    │   ├── stores/          # listado, categorías, detalle de negocio, menú por secciones
    │   │   ├── domain/entities/ (store.dart, store_summary.dart, category.dart, menu_section.dart, schedule.dart)
    │   │   ├── domain/usecases/ (get_nearby_stores.dart, get_store_detail.dart, get_store_menu.dart, get_categories.dart)
    │   │   ├── infrastructure/…
    │   │   └── presentation/pages/ (store_detail_page.dart, category_stores_page.dart)
    │   ├── products/        # detalle de producto, variantes, opciones, validación de selección
    │   │   └── domain/entities/ (product.dart, product_variant.dart, product_option.dart, product_selection.dart)
    │   ├── cart/            # carrito server-side + diálogo de conflicto de negocio + issues
    │   ├── checkout/        # quote, método de pago, vuelto en efectivo, cupón, confirmación
    │   ├── orders/          # confirmación, tracking (WebSocket), historial, detalle, repetir
    │   ├── addresses/       # CRUD + selector con mapa
    │   ├── profile/         # perfil, ajustes, logout
    │   ├── notifications/   # Fase 3
    │   └── reviews/         # Fase 4
    │   # Todas (salvo home) siguen el mismo esqueleto domain/infrastructure/presentation que auth/.
    │
    └── shared/
        └── widgets/
            ├── app_button.dart, app_text_field.dart
            ├── skeleton/ (skeleton_box.dart, skeleton_list.dart)
            ├── async_value_view.dart   # loading / error / empty / data de forma uniforme
            ├── empty_view.dart, error_view.dart
            ├── confirm_dialog.dart     # usado por conflicto de carrito y reorder
            ├── network_image.dart      # wrapper de cached_network_image
            ├── price_text.dart
            └── quantity_stepper.dart
```

**Reglas que se hacen cumplir**

- `domain/` no importa `package:flutter`, `dio`, `json_annotation` ni nada de `infrastructure/`. Se valida con un lint de imports (`custom_lint`) o con un test de arquitectura.
- Los Widgets solo leen estado y llaman métodos del controller. La lógica, como "¿esta selección de opciones es válida?" o "¿puedo agregar este producto?", vive en entidades o use cases.
- Los repositorios devuelven `Result<T>`, nunca lanzan excepciones hacia presentation.
- Un feature nunca importa el `domain/` ni el `infrastructure/` de otro. Si necesita datos de otro feature, consume sus **providers públicos** desde presentation (por eso `home` no tiene dominio propio).
- **Las entidades de dominio no llevan anotaciones** de persistencia ni de serialización (Isar, Hive, `@JsonSerializable`, Drift). Si se agrega caché local, se usa un modelo propio en `infrastructure/models` con su mapper.
- **Value objects (DDD)**: los conceptos con reglas propias (`Money`, `EmailAddress`, `Password`, `PhoneNumber`, `GeoCoordinates`, `Quantity`) son value objects inmutables. Se validan al construirse (`EmailAddress.create(raw)` devuelve `Validated<EmailAddress>`: `Valid(valor)` o `Invalid(ValueFailure)`; `Result<T>` queda para operaciones que pueden fallar por red o negocio), se comparan por valor y las entidades los usan en lugar de `String`/`int` sueltos. Los formularios validan con esos mismos value objects, así las reglas no se duplican en los Widgets. Solo se crean cuando tienen una regla real; un `name` sin restricciones sigue siendo `String`.
- **Entidades con comportamiento**: la lógica que pertenece a una entidad vive en ella, no en un servicio aparte (p. ej. `ProductSelection.isValid`, `ProductSelection.unitPrice`, `Cart.canAdd(product)`, `Order.canBeCancelled`). Los use cases orquestan (repositorio + entidades); no reimplementan reglas.
- **Los contratos de datasource viven en `infrastructure/`**, no en `domain/`: el dominio solo conoce el repositorio. Un repositorio existe porque agrega algo (convierte errores a `Result`, combina fuentes remota y local, maneja caché); si solo reenviaría llamadas, se replantea.
- **Un solo barrel por feature** (`features/<feature>/<feature>.dart`) que exporta su API pública. Otros features y el router importan solo ese archivo. No se crean barrels por carpeta interna, porque esconden dependencias y facilitan imports circulares.
- **Cada página declara `static const name`** y la navegación usa `context.goNamed(StoreDetailPage.name, pathParameters: …)`, nunca strings sueltos.

---

## 3. Estructura del backend NestJS (`backend/`)

```
backend/
├── Dockerfile                  # multi-stage (deps → build → runtime node:22-alpine)
├── package.json
├── tsconfig.json
├── .env.example
├── prisma/
│   ├── schema.prisma
│   ├── migrations/             # la primera migración incluye TODO el schema inicial
│   └── seed.ts
├── test/
│   ├── e2e/ (auth.e2e-spec.ts, cart.e2e-spec.ts, checkout.e2e-spec.ts, order-status.e2e-spec.ts)
│   ├── utils/ (test-app.factory.ts, db-reset.ts, factories.ts)
│   └── jest-e2e.json
└── src/
    ├── main.ts                     # bootstrap: helmet, cors, ValidationPipe, swagger, prefix /api/v1
    ├── app.module.ts
    ├── config/
    │   ├── env.validation.ts       # esquema zod; si falta una variable, la app no arranca
    │   ├── app.config.ts, auth.config.ts, database.config.ts
    ├── common/
    │   ├── decorators/ (current-user.decorator.ts, roles.decorator.ts, public.decorator.ts)
    │   ├── guards/ (jwt-auth.guard.ts [global], roles.guard.ts)
    │   ├── filters/ (all-exceptions.filter.ts)        # formato de error estándar + Prisma errors
    │   ├── interceptors/ (request-id / logging si hace falta)
    │   ├── pipes/ (parse-cuid.pipe.ts)
    │   ├── exceptions/ (app.exception.ts, error-codes.ts)
    │   ├── dto/ (page-query.dto.ts, cursor-query.dto.ts, paginated-response.dto.ts)
    │   └── utils/ (geo.ts [haversine], money.ts [IGV], order-code.ts)
    ├── database/
    │   ├── prisma.module.ts        # @Global
    │   └── prisma.service.ts
    └── modules/
        ├── health/                 # GET /health (liveness + DB)
        ├── auth/                            # agrupado por responsabilidad (ver reglas abajo)
        │   ├── auth.module.ts, auth.controller.ts, auth.service.ts
        │   ├── jwt-auth.guard.ts            # guard global; valida firma/exp sin consultar la BD
        │   ├── dto/auth.dto.ts
        │   ├── otp/ (otp.service.ts, otp.service.spec.ts)   # códigos SMS: hash, vencimiento, intentos
        │   ├── tokens/tokens.service.ts     # access JWT + refresh rotativo + registration token
        │   └── sms/sms-sender.ts            # abstracción del proveedor de SMS
        ├── users/          (users.controller|service, dto/update-me.dto.ts)
        ├── addresses/      (controller, service, dto/)
        ├── cities/         (controller: GET /cities, /cities/resolve; service)
        ├── categories/     (controller, service)
        ├── promotions/     (controller, service)
        ├── stores/         (controller, service, store-hours.util.ts, dto/)
        ├── products/       (controller, service, product-search.queries.ts, dto/)
        ├── carts/          (controller, service, configuration-key.ts, dto/)
        ├── delivery/       (delivery.service.ts: distancia, cobertura, fee, ETA)  # sin controller
        ├── checkout/       (controller: POST /checkout/quote, pricing.service.ts)
        ├── orders/
        │   ├── orders.module.ts, orders.controller.ts, orders.service.ts
        │   ├── order-status.machine.ts      # transiciones permitidas por rol (función pura)
        │   ├── order-snapshot.factory.ts    # cart → OrderItems con snapshots
        │   ├── order-cancellation.service.ts # restaura stock, cupón y pago
        │   ├── orders.gateway.ts            # Fase 3 (Socket.IO)
        │   ├── events/order-status-changed.event.ts
        │   ├── dto/ (create-order.dto.ts, update-order-status.dto.ts, cancel-order.dto.ts)
        │   └── entities/order.entity.ts     # clase de respuesta para Swagger/serialización
        ├── payments/
        │   ├── payments.module.ts, payments.service.ts
        │   ├── providers/ (payment-provider.interface.ts, cash.provider.ts, [culqi.provider.ts…])
        │   └── payment-provider.registry.ts
        ├── coupons/        (service, controller admin)
        ├── couriers/       (controller, service)       # Fase 3
        ├── reviews/        (controller, service)       # Fase 4
        └── notifications/  (service, listeners/order-events.listener.ts, push/)  # Fase 3
```

**Organización de archivos**
- Los unit tests (`*.spec.ts`) van junto al archivo que prueban; los e2e, en `backend/test/`.
- Los módulos son planos (`x.module.ts`, `x.controller.ts`, `x.service.ts`, `dto/`). Cuando un módulo pasa de unos 10 archivos, se agrupa **por responsabilidad** (`auth/otp/`, `auth/tokens/`), no por tipo (`services/`, `controllers/`): así cada concepto queda junto con su test.

**Responsabilidades**: el Controller se encarga de HTTP, DTO, roles y status codes. El Service tiene los casos de negocio y las transacciones (`prisma.$transaction`). Prisma es la persistencia; no hay repositorios encima de Prisma. Las queries complejas o en SQL crudo (búsqueda con trigramas) van en un `*.queries.ts` del módulo.

---

## 4. Modelo inicial de base de datos

### Convenciones

- IDs `String @default(cuid())`: no son secuenciales ni adivinables.
- **Dinero en `Int` (céntimos)** con `currency` en City/Order (`PEN`). Nunca `Float`.
- Timestamps `createdAt`/`updatedAt` en las tablas mutables. Soft delete (`deletedAt`) solo en Product, Store y Address, porque se referencian en historial.
- Precios **con IGV incluido** (la práctica en Perú), incluido el delivery fee. `taxTotal = total − round(total / 1.18)` se guarda en Order como dato informativo.
- Coordenadas en `Decimal(9,6)`. PostGIS queda para cuando haya volumen real.
- **La primera migración crea todo el schema inicial**, aunque los módulos se implementen por fase. Así el seed (que incluye courier y cupones) funciona desde la Fase 1 y se evitan migraciones que rehagan tablas.
- Usuarios con pedidos no se borran (`onDelete: Restrict` en `Order.customer`): se desactivan con `isActive = false`.

### Aclaración de nombres

- **Category**: categoría global de negocio que se muestra en el Home (Restaurantes, Bodegas, Farmacia, Postres, Licores). Tiene relación M:N con Store a través de **StoreCategory**.
- **MenuSection**: sección del menú *dentro* de un negocio ("Hamburguesas", "Bebidas"). Es la "Categories" de Store en el requerimiento. Tiene otro nombre para no confundirla con Category.
- **Promotion**: banner del Home. Puede apuntar a un negocio y/o a un cupón.

### Esquema (borrador Prisma)

> **Desde v0.5 la fuente de verdad es `backend/prisma/schema.prisma`** (Prisma 7). El borrador de abajo queda como referencia histórica; las diferencias están en [Cambios v0.4 → v0.5](#cambios-v04--v05).

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}

datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  extensions = [pg_trgm, unaccent]
}

enum Role              { CUSTOMER MERCHANT COURIER ADMIN }
enum OrderStatus       { PENDING CONFIRMED PREPARING READY_FOR_PICKUP PICKED_UP ON_THE_WAY DELIVERED CANCELLED }
enum PaymentMethodType { CASH CARD OTHER }       // YAPE, PLIN… se agregan como valores nuevos
enum PaymentStatus     { PENDING AUTHORIZED PAID FAILED REFUNDED CANCELLED }
enum CouponType        { PERCENTAGE FIXED_AMOUNT FREE_DELIVERY }
enum CourierStatus     { OFFLINE AVAILABLE BUSY }
enum NotificationType  { ORDER_STATUS PROMOTION SYSTEM }

// ───────────────────────── Ciudad y usuarios ─────────────────────────

model City {
  id              String   @id @default(cuid())
  name            String
  slug            String   @unique
  timezone        String   @default("America/Lima")
  currency        String   @default("PEN")
  centerLat       Decimal  @db.Decimal(9, 6)
  centerLng       Decimal  @db.Decimal(9, 6)
  baseDeliveryFee Int                               // céntimos
  feePerKm        Int                               // céntimos por km
  routeFactor     Decimal  @default(1.3) @db.Decimal(3, 2)  // línea recta → distancia por calle
  maxDeliveryKm   Decimal  @db.Decimal(5, 2)
  avgSpeedKmh     Int      @default(20)             // para ETA
  isActive        Boolean  @default(true)
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  stores     Store[]
  couriers   Courier[]
  addresses  Address[]
  orders     Order[]
  coupons    Coupon[]
  promotions Promotion[]
}

model User {
  id           String   @id @default(cuid())
  email        String   @unique
  phone        String?  @unique
  passwordHash String
  firstName    String
  lastName     String
  avatarUrl    String?
  isActive     Boolean  @default(true)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  roles             UserRole[]
  refreshTokens     RefreshToken[]
  addresses         Address[]
  cart              Cart?
  orders            Order[]
  ownedStores       Store[]
  courier           Courier?
  reviews           Review[]
  notifications     Notification[]
  devices           Device[]
  couponRedemptions CouponRedemption[]
}

model UserRole {                       // entidad "Role": un usuario puede tener varios roles
  userId String
  role   Role
  user   User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@id([userId, role])
}

model RefreshToken {
  id           String    @id @default(cuid())
  userId       String
  familyId     String                   // todos los tokens de una misma sesión/dispositivo
  tokenHash    String    @unique        // SHA-256 del token opaco; nunca el token en claro
  expiresAt    DateTime
  revokedAt    DateTime?
  replacedById String?
  userAgent    String?
  createdAt    DateTime  @default(now())
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([familyId])
}

model Address {
  id          String    @id @default(cuid())
  userId      String
  cityId      String?                   // se resuelve por cobertura; null = fuera de cobertura
  label       String                    // "Casa", "Trabajo"
  addressLine String
  reference   String?
  latitude    Decimal   @db.Decimal(9, 6)
  longitude   Decimal   @db.Decimal(9, 6)
  isDefault   Boolean   @default(false)
  deletedAt   DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  user   User    @relation(fields: [userId], references: [id], onDelete: Cascade)
  city   City?   @relation(fields: [cityId], references: [id])
  orders Order[]

  @@index([userId])
}

// ───────────────────────── Catálogo ─────────────────────────

model Category {
  id        String  @id @default(cuid())
  name      String
  slug      String  @unique
  iconUrl   String?
  sortOrder Int     @default(0)

  stores StoreCategory[]
}

model Store {
  id                String    @id @default(cuid())
  cityId            String
  ownerId           String                   // MERCHANT dueño (StoreMember más adelante si hay staff)
  name              String
  slug              String
  description       String?
  logoUrl           String?
  coverUrl          String?
  phone             String?
  addressLine       String
  latitude          Decimal   @db.Decimal(9, 6)
  longitude         Decimal   @db.Decimal(9, 6)
  deliveryRadiusKm  Decimal?  @db.Decimal(5, 2)   // override de City.maxDeliveryKm
  minOrderAmount    Int       @default(0)
  avgPrepMinutes    Int       @default(20)
  isActive          Boolean   @default(true)
  isAcceptingOrders Boolean   @default(true)       // pausa manual del merchant
  ratingAvg         Decimal   @default(0) @db.Decimal(2, 1)   // desnormalizado
  ratingCount       Int       @default(0)
  deletedAt         DateTime?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt

  city         City            @relation(fields: [cityId], references: [id])
  owner        User            @relation(fields: [ownerId], references: [id])
  categories   StoreCategory[]
  schedules    StoreSchedule[]
  menuSections MenuSection[]
  products     Product[]
  carts        Cart[]
  orders       Order[]
  reviews      Review[]
  coupons      Coupon[]
  promotions   Promotion[]

  @@unique([cityId, slug])
  @@index([cityId, isActive])
  @@index([latitude, longitude])
}

model StoreCategory {
  storeId    String
  categoryId String
  store      Store    @relation(fields: [storeId], references: [id], onDelete: Cascade)
  category   Category @relation(fields: [categoryId], references: [id], onDelete: Cascade)

  @@id([storeId, categoryId])
}

model StoreSchedule {
  id        String @id @default(cuid())
  storeId   String
  dayOfWeek Int                          // 0 = domingo … 6 = sábado
  opensAt   Int                          // minutos desde 00:00 (hora local de la ciudad)
  closesAt  Int                          // si closesAt < opensAt, el turno cruza medianoche
  store     Store  @relation(fields: [storeId], references: [id], onDelete: Cascade)

  @@index([storeId, dayOfWeek])
}

model MenuSection {
  id        String    @id @default(cuid())
  storeId   String
  name      String
  sortOrder Int       @default(0)
  store     Store     @relation(fields: [storeId], references: [id], onDelete: Cascade)
  products  Product[]
}

model Product {
  id            String    @id @default(cuid())
  storeId       String
  menuSectionId String?
  name          String
  description   String?
  imageUrl      String?
  basePrice     Int                      // céntimos; si hay variantes, manda el precio de la variante
  isAvailable   Boolean   @default(true)
  stock         Int?                     // null = no se controla stock (lo típico en restaurantes)
  isFeatured    Boolean   @default(false)
  sortOrder     Int       @default(0)
  deletedAt     DateTime?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  store       Store           @relation(fields: [storeId], references: [id])
  menuSection MenuSection?    @relation(fields: [menuSectionId], references: [id], onDelete: SetNull)
  variants    ProductVariant[]
  options     ProductOption[]
  cartItems   CartItem[]
  orderItems  OrderItem[]

  @@index([storeId, isAvailable])
  // búsqueda: índice GIN con gin_trgm_ops sobre unaccent(lower(name)) (migración SQL manual)
}

model ProductVariant {                   // p. ej. tamaño: Personal / Mediana / Familiar
  id          String     @id @default(cuid())
  productId   String
  name        String
  price       Int                        // precio absoluto de la variante
  isAvailable Boolean    @default(true)
  sortOrder   Int        @default(0)
  product     Product    @relation(fields: [productId], references: [id], onDelete: Cascade)
  cartItems   CartItem[]
}

model ProductOption {                    // grupo: "Elige tu salsa", "Extras"
  id        String               @id @default(cuid())
  productId String
  name      String
  minSelect Int                  @default(0)   // minSelect ≥ 1 ⇒ obligatorio
  maxSelect Int                  @default(1)
  sortOrder Int                  @default(0)
  product   Product              @relation(fields: [productId], references: [id], onDelete: Cascade)
  values    ProductOptionValue[]
}

model ProductOptionValue {
  id              String           @id @default(cuid())
  optionId        String
  name            String
  priceDelta      Int              @default(0)
  isAvailable     Boolean          @default(true)
  sortOrder       Int              @default(0)
  option          ProductOption    @relation(fields: [optionId], references: [id], onDelete: Cascade)
  cartItemOptions CartItemOption[]
}

model Promotion {                        // banners del Home
  id        String   @id @default(cuid())
  cityId    String
  storeId   String?                      // al tocar el banner → StoreDetail
  couponId  String?                      // cupón asociado (se muestra el código)
  title     String
  subtitle  String?
  imageUrl  String
  startsAt  DateTime
  endsAt    DateTime
  sortOrder Int      @default(0)
  isActive  Boolean  @default(true)

  city   City    @relation(fields: [cityId], references: [id])
  store  Store?  @relation(fields: [storeId], references: [id], onDelete: SetNull)
  coupon Coupon? @relation(fields: [couponId], references: [id], onDelete: SetNull)

  @@index([cityId, isActive, startsAt, endsAt])
}

// ───────────────────────── Carrito ─────────────────────────

model Cart {
  id        String     @id @default(cuid())
  userId    String     @unique           // un carrito por usuario
  storeId   String?                      // regla: un solo negocio; vuelve a null al quedar vacío
  updatedAt DateTime   @updatedAt
  user      User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  store     Store?     @relation(fields: [storeId], references: [id], onDelete: SetNull)
  items     CartItem[]
}

model CartItem {
  id               String           @id @default(cuid())
  cartId           String
  productId        String
  variantId        String?
  quantity         Int
  notes            String?
  configurationKey String   // hash(productId + variantId + optionValueIds ordenados + notes normalizadas)
  createdAt        DateTime         @default(now())
  cart             Cart             @relation(fields: [cartId], references: [id], onDelete: Cascade)
  product          Product          @relation(fields: [productId], references: [id], onDelete: Cascade)
  variant          ProductVariant?  @relation(fields: [variantId], references: [id], onDelete: Cascade)
  options          CartItemOption[]

  @@unique([cartId, configurationKey])
}

model CartItemOption {
  cartItemId    String
  optionValueId String
  cartItem      CartItem           @relation(fields: [cartItemId], references: [id], onDelete: Cascade)
  optionValue   ProductOptionValue @relation(fields: [optionValueId], references: [id], onDelete: Cascade)

  @@id([cartItemId, optionValueId])
}

// ───────────────────────── Pedidos ─────────────────────────

model Order {
  id                  String            @id @default(cuid())
  code                String            @unique   // público y legible: "CHK-7F3K9Q"
  idempotencyKey      String?                     // header Idempotency-Key de POST /orders
  customerId          String
  storeId             String
  courierId           String?
  cityId              String
  status              OrderStatus       @default(PENDING)
  // snapshot de la dirección
  addressId           String?                     // referencia débil
  deliveryLabel       String
  deliveryAddressLine String
  deliveryReference   String?
  deliveryLat         Decimal           @db.Decimal(9, 6)
  deliveryLng         Decimal           @db.Decimal(9, 6)
  // snapshot del negocio
  storeName           String
  // montos (céntimos), todos calculados por el backend
  subtotal            Int
  deliveryFee         Int
  discountTotal       Int               @default(0)
  taxTotal            Int               @default(0)   // IGV incluido, informativo
  total               Int
  currency            String
  distanceMeters      Int                             // distancia estimada por calle
  couponId            String?
  couponCode          String?                         // snapshot
  paymentMethod       PaymentMethodType
  cashChangeFor       Int?                            // "¿con cuánto pagas?" (solo CASH)
  notes               String?
  cancelReason        String?
  cancelledBy         Role?
  estimatedDeliveryAt DateTime?
  deliveredAt         DateTime?
  createdAt           DateTime          @default(now())
  updatedAt           DateTime          @updatedAt

  customer         User                 @relation(fields: [customerId], references: [id], onDelete: Restrict)
  store            Store                @relation(fields: [storeId], references: [id])
  courier          Courier?             @relation(fields: [courierId], references: [id], onDelete: SetNull)
  city             City                 @relation(fields: [cityId], references: [id])
  address          Address?             @relation(fields: [addressId], references: [id], onDelete: SetNull)
  coupon           Coupon?              @relation(fields: [couponId], references: [id], onDelete: SetNull)
  items            OrderItem[]
  statusHistory    OrderStatusHistory[]
  payment          Payment?
  review           Review?
  couponRedemption CouponRedemption?

  @@unique([customerId, idempotencyKey])
  @@index([customerId, createdAt])
  @@index([storeId, status])
  @@index([courierId, status])
}

model OrderItem {                        // snapshot completo: no depende del Product actual
  id          String            @id @default(cuid())
  orderId     String
  productId   String?                    // referencia débil
  variantId   String?                    // para restaurar stock/reorder; sin FK
  productName String
  variantName String?
  imageUrl    String?
  unitPrice   Int                        // base/variante + opciones
  quantity    Int
  subtotal    Int
  notes       String?
  order       Order             @relation(fields: [orderId], references: [id], onDelete: Cascade)
  product     Product?          @relation(fields: [productId], references: [id], onDelete: SetNull)
  options     OrderItemOption[]
}

model OrderItemOption {
  id            String    @id @default(cuid())
  orderItemId   String
  optionValueId String?                  // para reorder; sin FK
  optionName    String                   // "Extras"
  valueName     String                   // "Queso cheddar"
  priceDelta    Int
  orderItem     OrderItem @relation(fields: [orderItemId], references: [id], onDelete: Cascade)
}

model OrderStatusHistory {
  id            String       @id @default(cuid())
  orderId       String
  fromStatus    OrderStatus?
  toStatus      OrderStatus
  changedById   String?                  // userId; sin FK para no bloquear borrados
  changedByRole Role?
  note          String?
  createdAt     DateTime     @default(now())
  order         Order        @relation(fields: [orderId], references: [id], onDelete: Cascade)

  @@index([orderId, createdAt])
}

// ───────────────────────── Operación ─────────────────────────

model Courier {
  id             String        @id @default(cuid())
  userId         String        @unique
  cityId         String
  vehicleType    String                  // MOTO, BICI, AUTO
  plate          String?
  status         CourierStatus @default(OFFLINE)
  currentLat     Decimal?      @db.Decimal(9, 6)
  currentLng     Decimal?      @db.Decimal(9, 6)
  lastLocationAt DateTime?
  user           User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  city           City          @relation(fields: [cityId], references: [id])
  orders         Order[]
}

model Payment {
  id         String            @id @default(cuid())
  orderId    String            @unique
  method     PaymentMethodType
  provider   String                      // "cash", "culqi", "mercadopago"…
  status     PaymentStatus     @default(PENDING)
  amount     Int
  currency   String
  externalId String?                     // id del proveedor
  metadata   Json?                       // respuesta del proveedor, sin datos sensibles
  createdAt  DateTime          @default(now())
  updatedAt  DateTime          @updatedAt
  order      Order             @relation(fields: [orderId], references: [id], onDelete: Cascade)
}
// PaymentMethod: en el MVP es el enum PaymentMethodType + la config de métodos habilitados por
// ciudad/negocio. En la Fase 4 se agrega SavedPaymentMethod (tokens de tarjeta del proveedor, nunca el PAN).

model Coupon {
  id             String     @id @default(cuid())
  code           String     @unique      // se guarda en mayúsculas
  description    String?
  type           CouponType
  value          Int                     // % (0-100) o céntimos
  maxDiscount    Int?                    // tope para porcentaje
  minOrderAmount Int        @default(0)
  cityId         String?
  storeId        String?                 // null = aplica a todos
  startsAt       DateTime
  endsAt         DateTime
  usageLimit     Int?                    // null = sin límite global
  perUserLimit   Int        @default(1)
  usedCount      Int        @default(0)  // se incrementa condicionalmente (ver §9)
  isActive       Boolean    @default(true)

  city        City?              @relation(fields: [cityId], references: [id])
  store       Store?             @relation(fields: [storeId], references: [id])
  redemptions CouponRedemption[]
  orders      Order[]
  promotions  Promotion[]
}

model CouponRedemption {
  id        String   @id @default(cuid())
  couponId  String
  userId    String
  orderId   String   @unique
  createdAt DateTime @default(now())
  coupon    Coupon   @relation(fields: [couponId], references: [id])
  user      User     @relation(fields: [userId], references: [id])
  order     Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)

  @@index([couponId, userId])
}

model Review {
  id            String   @id @default(cuid())
  orderId       String   @unique         // una reseña por pedido
  userId        String
  storeId       String
  storeRating   Int                      // 1..5 (validado en DTO)
  courierRating Int?
  comment       String?
  createdAt     DateTime @default(now())
  order         Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  user          User     @relation(fields: [userId], references: [id])
  store         Store    @relation(fields: [storeId], references: [id])

  @@index([storeId, createdAt])
}

model Notification {
  id        String           @id @default(cuid())
  userId    String
  type      NotificationType
  title     String
  body      String
  data      Json?                        // { orderId, status }
  readAt    DateTime?
  createdAt DateTime         @default(now())
  user      User             @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, readAt])
  @@index([userId, createdAt])
}

model Device {                           // tokens FCM (Fase 3)
  id        String   @id @default(cuid())
  userId    String
  pushToken String   @unique
  platform  String
  updatedAt DateTime @updatedAt
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

**Relaciones clave**: User 1-N Address/Order/Review · User 1-1 Cart/Courier · Store N-M Category · Store 1-N MenuSection/Product/Order/Review/StoreSchedule/Promotion · Order 1-N OrderItem/OrderStatusHistory · Order 1-1 Payment/Review/CouponRedemption · Order N-1 Courier/Coupon/Address(débil).

---

## 5. Módulos NestJS

| Módulo | Responsabilidad | Fase |
|---|---|---|
| `config` (Nest ConfigModule) | variables de entorno tipadas y validadas | 1 |
| `database` | PrismaService global | 1 |
| `health` | liveness/readiness | 1 |
| `auth` | register, login, refresh rotativo, logout, JWT strategy | 1 |
| `users` | perfil `me`, roles | 1 |
| `cities` | ciudades, parámetros de delivery, resolución de cobertura | 1 |
| `categories` | categorías globales | 1 |
| `promotions` | banners vigentes por ciudad | 1 |
| `stores` | listado cercano/popular con cobertura, detalle, horarios (`isOpenNow`), menú | 1 |
| `products` | detalle, búsqueda (unaccent + trigramas) | 1 |
| `addresses` | CRUD con ownership, dirección por defecto | 2 |
| `carts` | carrito server-side, regla de un negocio, validación de opciones, `issues` | 2 |
| `delivery` | distancia (Haversine × routeFactor), cobertura, fee, ETA | 2 |
| `checkout` | `quote`: subtotal + delivery − descuento = total (+ IGV informativo) | 2 |
| `orders` | crear desde carrito (transacción, snapshots, idempotencia), listar, detalle, cancelar, reorder, máquina de estados | 2 |
| `payments` | registry de proveedores, `CashProvider` | 2 (cash) / 4 |
| `couriers` | perfil courier, disponibilidad, ubicación, asignación | 3 |
| `notifications` | in-app + push, escucha eventos de orders | 3 |
| `realtime` (gateway en orders) | Socket.IO `/ws`, rooms por pedido | 3 |
| `coupons` | validación y redención (el schema y el seed existen desde la Fase 1) | 4 |
| `reviews` | calificar pedido/negocio, rating desnormalizado | 4 |

---

## 6. Features Flutter

| Feature | Pantallas | Fase |
|---|---|---|
| `auth` | Splash, Onboarding, Login, Register | 1 |
| `home` | Home (dirección actual, notificaciones, búsqueda, categorías, populares, cerca de ti, promociones, pedidos recientes) | 1 (pedidos recientes en la 2) |
| `promotions` | banners del Home | 1 |
| `stores` | Listado por categoría, StoreDetail (header, horario, secciones del menú con tabs fijos) | 1 |
| `products` | ProductDetail (variantes, opciones min/max, cantidad, notas, precio en vivo) | 1 |
| `search` | Search (negocios + productos, debounce, recientes) | 1 |
| `profile` | Profile, editar datos, logout | 1 |
| `addresses` | Addresses, AddressSelector (mapa + pin + formulario) | 2 |
| `cart` | Cart (cantidades, conflicto de negocio, mínimo de pedido, ítems con issues) | 2 |
| `checkout` | Checkout (dirección, quote, método de pago, vuelto, notas), OrderConfirmation | 2 |
| `orders` | OrderHistory, OrderDetail, repetir pedido | 2 |
| `orders` (tracking) | OrderTracking (timeline + mapa + WebSocket) | 3 |
| `notifications` | lista, badge, push | 3 |
| `checkout` (cupones/pagos) | aplicar cupón, pago con tarjeta | 4 |
| `reviews` | calificar pedido | 4 |

**Estado de UI**: cada pantalla usa `AsyncValue` (Riverpod) y se renderiza con `AsyncValueView`, que tiene variantes **skeleton** (loading), **error** (con reintentar y el mensaje del Failure), **empty** (ilustración + CTA) y **data**. Los spinners solo se usan en botones mientras se envía algo.

---

## 7. Endpoints iniciales

**Convenciones**
- Prefijo `/api/v1` · JSON · fechas ISO-8601 UTC · dinero en céntimos `{ amount, currency }`.
- Swagger en `/docs` (solo fuera de prod).
- 🔒 = requiere JWT · el rol va entre corchetes.
- **Paginación:**
  - *offset* (`?page=&limit=` → `{ items, page, limit, total }`) en listados ordenados por cálculo (stores por distancia, búsqueda);
  - *cursor* (`?cursor=&limit=` → `{ items, nextCursor }`) en listas cronológicas (historial de pedidos, notificaciones).

### Auth (celular + código OTP, sin contraseña)
| Método | Ruta | Notas |
|---|---|---|
| POST | `/auth/otp/request` | `{ phone }` (9 dígitos, empieza con 9) → `{ phone, resendAfterSeconds, codeLength }` · reenvío cada 30 s, máx. 5 por hora · throttle 5/min |
| POST | `/auth/otp/verify` | `{ phone, code }` → `{ status: AUTHENTICATED, user, accessToken, refreshToken }` o `{ status: PROFILE_REQUIRED, registrationToken }` · 5 intentos por código · errores `OTP_INVALID` (422), `OTP_NOT_REQUESTED`/`OTP_EXPIRED` (409), `OTP_TOO_MANY_ATTEMPTS` (429) |
| POST | `/auth/register` | `{ registrationToken, firstName, lastName }` → `{ user, accessToken, refreshToken }` · siempre CUSTOMER · si el número ya tiene cuenta, inicia sesión con ella |
| POST | `/auth/refresh` | body `{ refreshToken }` → par nuevo (rotación) |
| POST | `/auth/logout` | **público e idempotente**, body `{ refreshToken }` → revoca su familia · 204 aunque ya esté revocado |

### Users
| Método | Ruta | Notas |
|---|---|---|
| GET | `/users/me` 🔒 | |
| PATCH | `/users/me` 🔒 | nombre, teléfono, avatar |

### Cities / Categories / Promotions
| Método | Ruta | Notas |
|---|---|---|
| GET | `/cities` | ciudades activas |
| GET | `/cities/resolve?lat=&lng=` | ¿la ubicación tiene cobertura? → ciudad |
| GET | `/categories` | categorías globales |
| GET | `/promotions?cityId=` | banners vigentes |

### Addresses 🔒 [CUSTOMER]
`GET /addresses` · `POST /addresses` · `PATCH /addresses/:id` · `DELETE /addresses/:id` (soft delete). Siempre filtradas por `userId` del token (ownership).

### Stores
| Método | Ruta | Notas |
|---|---|---|
| GET | `/stores?lat=&lng=&categoryId=&sort=distance\|popular\|rating&includeOutOfCoverage=false&page=&limit=` | por defecto solo negocios que entregan en esa ubicación · incluye `distanceKm`, `isOpenNow`, `deliversToYou`, `estimatedDeliveryFee`, `etaMinutes` |
| GET | `/stores/:id` | detalle + horarios |
| GET | `/stores/:id/products` | menú agrupado por `MenuSection` |

### Products / Search
| Método | Ruta | Notas |
|---|---|---|
| GET | `/products/:id` | variantes + opciones + valores |
| GET | `/products?search=&storeId=&page=&limit=` | búsqueda sin acentos (unaccent + pg_trgm) |
| GET | `/search?q=&lat=&lng=` | negocios + productos en una llamada para la pantalla Search |

### Cart 🔒 [CUSTOMER]
| Método | Ruta | Notas |
|---|---|---|
| GET | `/cart` | ítems + subtotal calculado por el server + `store` + `issues[]` (ítems no disponibles, precio cambiado, negocio cerrado) |
| POST | `/cart/items` | `{ productId, variantId?, optionValueIds[], quantity, notes? }` → **409 `CART_STORE_CONFLICT`** con `details: { currentStoreId, currentStoreName }` si el carrito es de otro negocio |
| PATCH | `/cart/items/:id` | `{ quantity, notes? }` (quantity 0 = eliminar) |
| DELETE | `/cart/items/:id` | si el carrito queda vacío, `storeId` vuelve a null |
| DELETE | `/cart` | vaciar |

### Checkout 🔒 [CUSTOMER]
| Método | Ruta | Notas |
|---|---|---|
| POST | `/checkout/quote` | `{ addressId, couponCode? }` → `{ subtotal, deliveryFee, discount, tax, total, distanceKm, etaMinutes, warnings[] }` |

### Orders 🔒
| Método | Ruta | Notas |
|---|---|---|
| POST | `/orders` [CUSTOMER] | `{ addressId, paymentMethod, cashChangeFor?, couponCode?, notes? }` + header `Idempotency-Key` → se crea a partir del carrito del servidor |
| GET | `/orders?cursor=&limit=` | CUSTOMER: sus pedidos · MERCHANT: los de sus negocios · COURIER: los asignados |
| GET | `/orders/:id` | con ownership según rol |
| POST | `/orders/:id/cancel` | `{ reason? }` · reglas por rol en la máquina de estados |
| POST | `/orders/:id/reorder` [CUSTOMER] | `{ replaceCart?: boolean }` · si el carrito no está vacío y `replaceCart` no es true → **409 `CART_NOT_EMPTY`** · devuelve el carrito nuevo + lo que no se pudo agregar |
| POST | `/orders/:id/review` [CUSTOMER] | Fase 4, solo si está DELIVERED |

### Negocio y repartidor 🔒 [MERCHANT] · [COURIER]
> Esta sección reemplaza el borrador inicial (`PATCH /orders/:id/status`, `/couriers/me/*`). El contrato vigente está en `backend/src/modules/merchant` y `backend/src/modules/couriers`; la operación se describe en [OPERACION.md](OPERACION.md).

- **Negocio** (`merchant/*`): `GET merchant/orders` · `GET merchant/orders/:id` · `POST merchant/orders/:id/accept` · `POST merchant/orders/:id/status` · `POST merchant/orders/:id/cancel` · `GET merchant/stores` · `PATCH merchant/stores/:id` · `PATCH merchant/products/:id` · `GET merchant/summary`
- **Repartidor** (`courier/*`): `GET courier/me` · `PATCH courier/me/status` · `GET courier/orders/available` · `GET courier/orders` · `POST courier/orders/:id/accept` · `POST courier/orders/:id/status` · `GET courier/me/summary`

### Notifications (Fase 3) 🔒
`GET /notifications?cursor=&limit=` · `PATCH /notifications/:id/read` · `POST /notifications/read-all` · `POST /devices` (registrar token push)

### WebSocket (Socket.IO)
- Namespace `/ws` (`modules/realtime`). El access token va en `auth.token` del handshake y **se valida solo al conectar**: sin token válido, el cliente recibe `connect_error` con mensaje `UNAUTHORIZED`, refresca y reconecta.
- Los eventos solo avisan qué cambió; la app vuelve a pedir el detalle o la lista por REST, que sigue siendo la fuente de verdad. Se emiten con `@nestjs/event-emitter` después del commit.
- **Cliente:** emite `order.subscribe { orderId }` (ack `{ ok }` o `{ ok: false, code: 'NOT_FOUND' }`; valen el cliente, el negocio y el repartidor del pedido) y recibe `order.updated { orderId, status }` y `courier.location { orderId, lat, lng, at }` (solo con el pedido `ON_THE_WAY`).
- **Negocio:** al conectar entra a `store:{id}` de sus negocios y recibe `store.orders.changed { orderId, status }`, incluido el pedido nuevo (`RECEIVED`).
- **Repartidor:** entra a `couriers:{cityId}` y recibe `courier.orders.changed` cuando un pedido queda listo, lo toman o se cancela.
- **Ubicación:** el repartidor manda `POST /courier/me/location { lat, lng }` cada ~10 s (se guarda una cada 2 s como máximo, solo la última). El detalle del pedido trae `courier.location` mientras va en camino y si tiene menos de 2 minutos; también `store.location` y `address.location`.
- Una sola instancia: con varias hace falta el adapter de Redis para Socket.IO.

### Formato de error
```json
{ "statusCode": 409, "code": "CART_STORE_CONFLICT", "message": "Cart contains products from another store", "details": { "currentStoreId": "…", "currentStoreName": "Pollería El Sol" }, "requestId": "b1f…" }
```
Catálogo de códigos en `common/exceptions/error-codes.ts`, documentado en Swagger:
- **Generales:** `VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `RATE_LIMITED`, `INTERNAL_ERROR`.
- **Auth:** `TOKEN_EXPIRED`, `INVALID_REFRESH_TOKEN`, `OTP_NOT_REQUESTED`, `OTP_EXPIRED`, `OTP_INVALID`, `OTP_TOO_MANY_ATTEMPTS`, `OTP_RESEND_TOO_SOON`, `OTP_TOO_MANY_REQUESTS`, `REGISTRATION_EXPIRED`, `USER_DISABLED`, `EMAIL_ALREADY_EXISTS`.
- **Catálogo:** `PRODUCT_UNAVAILABLE`, `PRODUCT_OUT_OF_STOCK`, `INVALID_PRODUCT_OPTIONS`.
- **Carrito:** `CART_STORE_CONFLICT`, `CART_EMPTY`, `CART_NOT_EMPTY`.
- **Checkout:** `STORE_CLOSED`, `BELOW_MINIMUM_ORDER`, `ADDRESS_OUT_OF_COVERAGE`.
- **Cupones:** `COUPON_INVALID`, `COUPON_EXPIRED`, `COUPON_EXHAUSTED`.
- **Pedidos:** `INVALID_STATUS_TRANSITION`, `COURIER_NOT_ASSIGNED`.

---

## 8. Flujo completo: de "agregar producto" a "pedido entregado"

1. **ProductDetail (Flutter)**: el usuario elige una variante y opciones. La entidad `ProductSelection` valida en el dominio los mínimos y máximos por grupo y calcula un precio *orientativo*. El botón "Agregar · S/ 24.90" se habilita solo si la selección es válida.
2. **CartController → AddToCart use case → CartRepository → `POST /cart/items`**.
3. **Backend `CartsService.addItem`**:
   - carga el producto, la variante y los valores de opción, y valida que existan, pertenezcan al producto, estén disponibles y cumplan min/max → si no, `INVALID_PRODUCT_OPTIONS` / `PRODUCT_UNAVAILABLE`;
   - si `cart.storeId` es de otro negocio → **409 `CART_STORE_CONFLICT`** con el nombre del negocio actual;
   - calcula `configurationKey` (producto + variante + opciones + notas): si ya existe la misma configuración, suma la cantidad; si no, crea una línea nueva. Si el carrito estaba vacío, fija `storeId`;
   - devuelve el carrito con precios **actuales** calculados por el servidor.
4. **Conflicto** (Flutter): el repositorio mapea el 409 a `CartConflictFailure(currentStoreName)`. El controller muestra *"Tu carrito contiene productos de otro negocio. ¿Deseas vaciarlo y comenzar uno nuevo?"*. Si el usuario acepta, se llama `DELETE /cart` y se reintenta `POST /cart/items`.
5. **Cart**:
   - modifica cantidades (`PATCH`) con actualización optimista y rollback si falla;
   - muestra los `issues` que devuelve el servidor (ítem agotado, precio cambiado) y un aviso si no se alcanza `minOrderAmount`.
6. **Checkout**: se elige la dirección (por defecto o `AddressSelector` con mapa). Cada cambio de dirección o cupón llama a **`POST /checkout/quote`**:
   - `DeliveryService`:
     - calcula `km = haversine(tienda, dirección) × city.routeFactor`;
     - si supera `store.deliveryRadiusKm ?? city.maxDeliveryKm` → `ADDRESS_OUT_OF_COVERAGE`;
     - `fee = baseDeliveryFee + ceil(km) × feePerKm`;
     - `eta = avgPrepMinutes + km / avgSpeedKmh`.
   - `PricingService`: recalcula el subtotal con precios actuales de BD, aplica el cupón (Fase 4), calcula el total y el IGV informativo. **Nada viene del cliente salvo IDs.**
7. **Método de pago**: CASH en el MVP, con campo opcional "¿con cuánto pagas?" (`cashChangeFor`, validado ≥ total). CARD/Yape se agregan en la Fase 4.
8. **Confirmar → `POST /orders`** con un `Idempotency-Key`. La app lo genera al abrir el checkout y lo regenera si cambian carrito, dirección, cupón o método de pago; así un doble tap o un reintento de red no crean dos pedidos, pero un pedido distinto sí recibe una key nueva.
9. **Backend `OrdersService.create`**: si ya existe un pedido con `(customerId, idempotencyKey)`, lo devuelve. Si no, dentro de `prisma.$transaction`:
   1. revalida todo: negocio activo, abierto y aceptando pedidos (`STORE_CLOSED`), productos disponibles, cobertura, mínimo;
   2. **stock**: por cada ítem con stock controlado, `updateMany where id = … and stock >= qty` (decremento condicional). Si afecta 0 filas → `PRODUCT_OUT_OF_STOCK` y rollback completo;
   3. **cupón** (Fase 4): valida vigencia y límite por usuario, y hace `updateMany where id = … and (usageLimit is null or usedCount < usageLimit)` con `usedCount + 1`. Si afecta 0 filas → `COUPON_EXHAUSTED`;
   4. recalcula el total con el mismo `PricingService` del quote;
   5. crea `Order` con snapshots de dirección, negocio e ítems (`OrderItem` + `OrderItemOption` con nombres y precios congelados, más los IDs de referencia para reorder) y un `code` público;
   6. crea `OrderStatusHistory(null → PENDING)`;
   7. crea `Payment` a través del `PaymentProvider` del método elegido (cash → `PENDING`);
   8. registra `CouponRedemption` si hubo cupón;
   9. vacía el carrito (`storeId = null`).
   Después del commit emite el evento interno `order.created`.
10. **Flutter** navega a **OrderConfirmation** y luego a **OrderTracking**, se suscribe por WebSocket a `order:{id}` y hace fetch inicial de `GET /orders/:id`.
11. **Merchant** (panel futuro o, por ahora, Swagger/admin): `PATCH /orders/:id/status` con CONFIRMED y luego PREPARING, READY_FOR_PICKUP. Cada cambio:
    - pasa por `order-status.machine.ts`, que valida transición + rol + pertenencia (`INVALID_STATUS_TRANSITION` / `FORBIDDEN` / `NOT_FOUND`);
    - guarda historial en la misma transacción;
    - emite `order.status_changed` → el **gateway** envía `order.updated` al room y el **NotificationsListener** crea la notificación in-app y el push.
12. **Courier**: acepta o es asignado ("Repartidor asignado") → PICKED_UP (requiere courier asignado, si no `COURIER_NOT_ASSIGNED`) → ON_THE_WAY, y envía su ubicación cada ~10 s (`courier.location`).
13. **DELIVERED**: en la misma transacción se guarda `deliveredAt` y el Payment en efectivo pasa a `PAID`. Flutter muestra la pantalla de entregado con CTA "Calificar pedido" (Fase 4).
14. **Después**: el pedido aparece en OrderHistory (renderizado **solo con snapshots**) y se puede **repetir**. `POST /orders/:id/reorder` responde 409 `CART_NOT_EMPTY` si hay carrito; la app confirma y reintenta con `replaceCart: true`. El carrito nuevo usa precios actuales e informa lo que ya no está disponible.

**Cancelación** (`OrderCancellationService`, una transacción):
- estado → CANCELLED con `cancelReason` y `cancelledBy`, más su historial;
- **restaura el stock** de los ítems con stock controlado;
- borra la `CouponRedemption` y decrementa `usedCount`;
- `Payment` pasa a `CANCELLED`, o a `REFUNDED` vía proveedor si ya estaba pagado online;
- después del commit emite `order.status_changed`.

**Máquina de estados**

```
PENDING ─▶ CONFIRMED ─▶ PREPARING ─▶ READY_FOR_PICKUP ─▶ PICKED_UP ─▶ ON_THE_WAY ─▶ DELIVERED
   │           │            │               │                │            │
   └───────────┴────────────┴───────────────┴────────────────┴────────────┴──▶ CANCELLED
```

| Rol | Puede hacer | Alcance |
|---|---|---|
| CUSTOMER | cancelar en PENDING o CONFIRMED | solo sus pedidos |
| MERCHANT | CONFIRMED, PREPARING, READY_FOR_PICKUP; cancelar hasta READY_FOR_PICKUP (con motivo) | solo pedidos de negocios cuyo `ownerId` es el usuario |
| COURIER | PICKED_UP (desde READY_FOR_PICKUP), ON_THE_WAY, DELIVERED | solo pedidos asignados a ese courier |
| ADMIN | cualquier transición válida; cancelar en cualquier estado anterior a DELIVERED | todos |

DELIVERED y CANCELLED son estados finales. En Flutter, "Repartidor asignado" es un hito derivado (`courierId != null`), no un estado nuevo del enum.

---

## 9. Decisiones técnicas importantes

**Backend**
1. **Monolito modular sin capas artificiales**: Controller → Service → Prisma. Los módulos exportan solo los services que otros necesitan.
2. **Eventos internos (`@nestjs/event-emitter`)** para efectos secundarios (notificaciones, WebSocket, más adelante analytics). Se emiten **después del commit**. Si en el futuro hace falta durabilidad, se cambia por un outbox + cola (BullMQ/Redis) sin tocar los emisores.
3. **Auth**:
   - Access JWT de 15 min (HS256, `sub`, `roles`). `JwtStrategy` solo valida firma y expiración, **sin consultar la BD** por request. Un cambio de rol o una desactivación se aplica como máximo en 15 min, cuando falla el refresh, y lo aceptamos.
   - Refresh token **opaco y aleatorio** (256 bits), 30 días, guardado en BD **hasheado con SHA-256**, **rota** en cada uso. Si alguien reutiliza un token ya rotado, se revoca toda la familia (detección de robo). El refresh sí verifica que el usuario siga activo.
   - Logout público e idempotente con el refresh token en el body.
   - Contraseñas con **argon2id**.
   - El register siempre asigna CUSTOMER; los demás roles se crean por seed o admin.
   - Guard JWT global que se exime con `@Public()`, y `RolesGuard` con `@Roles()`.
4. **Ownership** en services: toda query de recursos del usuario filtra por `userId`, por negocio (`store.ownerId`) o por courier asignado, según el rol. Si el recurso es ajeno, se responde **404** en vez de 403 para no revelar que existe.
5. **Dinero en céntimos (Int)** en BD, API y Flutter (`Money` value object). Una sola función de pricing se usa tanto en quote como en creación de pedido, así no pueden divergir. IGV incluido: `tax = total − round(total / 1.18)`.
6. **Carrito en servidor**: sirve en varios dispositivos, permite validar precios y es la base del pedido. La regla de un negocio por carrito vive en `Cart.storeId`, que se fija con el primer ítem y se libera al vaciarse.
7. **Idempotencia en `POST /orders`**: `@@unique([customerId, idempotencyKey])`. Si llega repetido, se devuelve el pedido existente con 200 en vez de 201.
8. **Concurrencia sin locks explícitos**: stock y uso de cupones se descuentan con `updateMany` condicional dentro de la transacción. Si afecta 0 filas, se aborta con el error de negocio correspondiente. Alcanza para un monolito sobre Postgres; no hace falta `SELECT … FOR UPDATE`.
9. **Geo en el MVP**: Haversine en TypeScript × `routeFactor` por ciudad (la distancia en línea recta subestima la real por calle), con prefiltro por bounding box sobre el índice lat/lng. En una ciudad pequeña sobra. PostGIS, polígonos de cobertura o una API de rutas quedan para cuando lo pidan el volumen o el negocio.
10. **Búsqueda**: extensiones `unaccent` + `pg_trgm` con índice GIN sobre `unaccent(lower(name))`, así "aji de gallina" encuentra "Ají de Gallina". La query en SQL crudo vive en `product-search.queries.ts`.
11. **Pagos**: interfaz `PaymentProvider { createPayment, confirm, refund, handleWebhook }` + `PaymentProviderRegistry` que resuelve por método. Esta abstracción **sí** se justifica, porque ya hay 5 proveedores previstos. Order solo conoce `paymentMethod` y su `Payment`, nunca a Culqi o Mercado Pago directamente.
12. **Errores**: `AppException(code, httpStatus, message, details?)` + `AllExceptionsFilter`, que normaliza validación (class-validator → `VALIDATION_ERROR` con detalle por campo), Prisma (`P2002` → 409, `P2025` → 404) y errores desconocidos (500 sin stacktrace hacia el cliente).
13. **Seguridad**: ValidationPipe global (`whitelist`, `forbidNonWhitelisted`, `transform`), Helmet, CORS por lista blanca desde env, `@nestjs/throttler` (global suave y estricto en auth), secrets solo por env validado con zod, respuestas serializadas con DTOs de salida (nunca `passwordHash`), IDs cuid y `code` público para pedidos.
14. **Observabilidad**: `nestjs-pino` con logs JSON, `requestId` tomado de `X-Request-Id` o generado, propagado a logs y a la respuesta de error. `/health` con `@nestjs/terminus`. Prometheus, OpenTelemetry y Sentry se enchufan después sin cambiar el código de negocio.
15. **Testing**: Jest.
    - Unit tests de services con Prisma mockeado (`jest-mock-extended`).
    - Unit tests de funciones puras: máquina de estados, pricing, delivery fee, horarios, `configurationKey`.
    - Integración/e2e con Supertest contra un Postgres real en Docker (BD de test que se limpia entre suites), incluyendo los casos de concurrencia de stock y cupones.
16. **Docker Compose (dev)**: `postgres:16` + `api` (hot reload) + `adminer` opcional. Migraciones con `prisma migrate dev`. En deploy, `prisma migrate deploy` en el arranque.

**Flutter**
17. **Riverpod con `riverpod_generator`**: `AsyncNotifier` como controllers y providers como DI (datasource → repository → use case → controller). En tests se reemplaza cualquier capa con `ProviderContainer(overrides: …)`.
18. **Use cases**: una clase por acción con `call()`. Solo encapsulan lógica real (validar una selección, armar un reorder). Los triviales siguen existiendo para mantener una convención uniforme, pero se quedan en una línea. Ningún use case depende de otro feature.
19. **`Result<T>` y `Failure` como sealed classes de Dart 3**, sin dartz/fpdart. El `ApiErrorMapper` convierte `DioException` a `NetworkFailure`, `UnauthorizedFailure`, `ValidationFailure(fieldErrors)`, `NotFoundFailure`, `ServerFailure` o `BusinessFailure(code, details)`, y los features pueden definir los suyos (p. ej. `CartConflictFailure`, `CartNotEmptyFailure`). La UI nunca ve Dio.
20. **Refresh de token sin loops**:
    - `AuthInterceptor` basado en `QueuedInterceptor`, con un solo refresh en vuelo (un `Completer` compartido) mientras el resto de requests esperan.
    - El refresh usa una **instancia de Dio separada sin interceptor**.
    - Cada request se reintenta como máximo una vez (`options.extra['retried']`), y `/auth/*` nunca dispara refresh.
    - Si el refresh falla, se limpia la sesión y el `redirect` de GoRouter lleva a Login.
21. **Freezed** solo en states de UI y DTOs. Las entidades de dominio son clases inmutables simples (o Freezed sin JSON), y los DTOs usan `json_serializable` con mappers explícitos DTO ↔ entidad.
22. **Mapas encapsulados**: `AppMapView` (widget) + `LocationService` + `GeocodingService` en `core/maps`. Los features no importan `google_maps_flutter`. Cambiar a Mapbox es escribir otra implementación.
23. **Tiempo real**: `RealtimeClient` abstracto con implementación `socket_io_client`. El tracking combina el fetch inicial, los eventos y un polling de respaldo cada 30 s si el socket se cae. Si el token expira, reconecta con el token nuevo y se vuelve a suscribir.
24. **Testing Flutter**: `mocktail` para mocks, tests de use cases y repositories (datasource mockeado), tests de controllers con `ProviderContainer`, y widget tests donde aportan (ProductDetail, Cart, Login).
25. **Entornos** con `--dart-define-from-file` (dev/prod), sin secretos en el código. La API key de Maps se restringe por package/SHA.
26. **Identidad visual propia**: se define en `app/theme` (paleta, tipografía, radios, espaciado) con tokens, sin copiar Rappi ni PedidosYa. La propuesta de identidad (andina, cálida y moderna, coherente con "Apamuy") se presenta en la Fase 1 antes de construir pantallas.

**Lo que NO se hace en el MVP (a propósito)**: microservicios, CQRS, event sourcing, Redis, colas, PostGIS, i18n completo, panel web de merchant (el merchant opera vía endpoints y Swagger/seed hasta la Fase 3+), multi-tenant de marcas.

---

## 10. Roadmap de implementación

Cada paso termina con código compilando, tests verdes y un commit.

### Fase 0 — Fundaciones (corta)
- Monorepo, `.gitignore`, `.editorconfig`, README.
- `docker-compose.yml` con Postgres.
- CI mínima (GitHub Actions): lint + test del backend y `flutter analyze` + `flutter test`.

### Fase 1 — Catálogo y auth
**Backend**
1. Proyecto NestJS, ConfigModule con validación, Prisma, `/health`, pino + requestId, filtro de errores, ValidationPipe, Helmet, CORS, Swagger.
2. **Schema Prisma inicial completo** (todas las entidades de §4, extensiones `pg_trgm`/`unaccent` e índice de búsqueda) en la primera migración, verificado con `prisma validate`.
3. `auth` + `users`: register, login, refresh rotativo, logout, `me`, guards y roles, throttling. Unit + e2e.
4. `cities`, `categories`, `promotions`, `stores` (cercanos con cobertura, popular, detalle, menú, `isOpenNow`), `products` (detalle, búsqueda).
5. Seed: 1 ciudad (Espinar) con parámetros de delivery, 5 categorías, 5 negocios con horarios, menús, variantes y opciones, promociones, usuarios customer/merchant/courier/admin (con su registro `Courier`) y cupones de prueba.

**Flutter**
6. Proyecto, estructura, lints, tema e identidad visual, `core/` (Dio, interceptors, Result, Failure, secure storage), GoRouter con shell.
7. `auth`: Splash, Onboarding, Login, Register, restauración de sesión y refresh.
8. `home` (categorías, populares, cerca de ti, promociones), `search`.
9. `stores` (StoreDetail) y `products` (ProductDetail con validación de opciones).
10. Tests: use cases, repositories, controllers, widget tests de ProductDetail y Login.

### Fase 2 — Compra
**Backend**:
- `addresses` → `carts` (con `issues`) → `delivery` → `checkout/quote`.
- `orders`: creación transaccional con snapshots, idempotencia, stock condicional; listar, detalle, cancelar con restauración y reorder.
- `payments` con `CashProvider`.
- Máquina de estados + `PATCH /orders/:id/status`.
- E2E del flujo register → add to cart → quote → create order → update status → cancel.

**Flutter**: Addresses + AddressSelector (mapa), Cart (conflicto de negocio, issues, optimismo), Checkout (vuelto en efectivo), OrderConfirmation, OrderHistory, OrderDetail, repetir pedido, "Pedidos recientes" en Home.

### Fase 3 — Operación en tiempo real
**Backend**: `couriers` (estado, ubicación, aceptar/asignar), gateway Socket.IO con auth JWT y rooms, eventos `order.status_changed`, `notifications` (in-app + FCM), `Device`.
**Flutter**: OrderTracking (timeline, mapa con courier, WebSocket + fallback + reconexión), notificaciones (lista, badge, push, deep link al pedido).

### Fase 4 — Monetización y confianza
**Backend**: `coupons` (validación, límites con incremento condicional, redención y liberación al cancelar) integrado en pricing; `reviews` + rating desnormalizado; primer proveedor de pago online (Culqi o Mercado Pago) con webhook firmado e idempotente, y refund al cancelar.
**Flutter**: aplicar cupón en checkout, pago con tarjeta/Yape, calificar pedido.

### Después del MVP (según tracción)
Panel web de merchant/admin · app Apamuy Socios para negocios y repartidores (mismo proyecto Flutter, flavor `partner`; ver [OPERACION.md](OPERACION.md)) · PostGIS y zonas de cobertura · Redis (caché del catálogo, adapter de Socket.IO para varias instancias) · colas para notificaciones · Sentry/OpenTelemetry/Prometheus/Grafana/Loki · segunda ciudad.

---

## Cambios v0.4 → v0.5

La app Flutter se construyó antes que el backend y su contrato (los `Api*RemoteDataSource` y los fakes de `mobile/lib/features/*/infrastructure`) manda sobre este documento. El backend de la Fase 1 ya está implementado en `backend/` siguiendo ese contrato:

- **Auth por celular + OTP**, sin email ni contraseña: `/auth/otp/request`, `/auth/otp/verify`, `/auth/register` con `registrationToken` (JWT de 15 min con audiencia propia, no sirve como access token). `User.phone` es obligatorio y único; se quitan `email` obligatorio y `passwordHash`. Nueva tabla `OtpChallenge` (solo HMAC del código, vencimiento, intentos y consumo). El SMS va detrás de `SmsSender`; hasta tener proveedor se loguea, y fuera de producción `OTP_DEV_CODE` fija el código.
- **La bolsa vive en el dispositivo**: se eliminan `Cart`, `CartItem` y `CartItemOption`. `POST /orders` (Fase 2) recibe los ítems y el backend recalcula precios, disponibilidad y totales.
- **Estados del pedido** con los nombres de la app: `RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED`, más `CANCELLED`. "Repartidor asignado" pasa a ser un estado real.
- **Pedido**: dirección como snapshot (`addressTitle`, `addressStreet`, `addressRef`, coordenadas) sin `addressId`; se agregan `tip` y `scheduledFor`; métodos de pago `CASH`, `YAPE`, `PLIN`, `CARD`.
- **Calificación**: `POST /orders/:id/rating` `{ rating, comment }`; `Review` guarda un solo `rating`.
- **Cupones desde el inicio**: `POST /coupons/validate` (Fase 2) → `{ code, discount, label }`; `Coupon.label` es el texto que ve el cliente.
- **Negocio**: `tags`, `promoLabel`, `ownerDisplayName` (se expone como `ownerName`), `attendingSince` y `popularityScore` (orden "popular"). **Producto**: `isLocal` ("Hecho en Espinar"). **Courier**: `vehicleLabel` y `activeSince` para la tarjeta del repartidor.
- **Endpoints nuevos**: `/discovery/local-products`, `/discovery/popular-searches` (tabla `PopularSearch` con términos curados; el conteo de negocios se calcula) y `GET /cities`. `/promotions` y `/categories` devuelven arrays. `lat`/`lng` son opcionales en todo el catálogo: sin ellos se usa el centro de la ciudad.
- **Direcciones**: por ahora en el dispositivo; `Address` queda en el schema con `kind`/`label`/`street` para la sincronización futura.
- **Stack**: NestJS 11, Prisma 7 (generador `prisma-client` en CommonJS, `@prisma/adapter-pg`, URL en `prisma.config.ts`). Búsqueda con `immutable_unaccent()` + índices GIN de trigramas creados en la migración inicial. Postgres de desarrollo en el puerto 5433 (`docker-compose.yml`).
- **Tests e2e**: corren contra `chaski_test`, que se migra con `migrate deploy`, se vacía y se siembra en cada corrida.

## Cambios v0.3 → v0.4

Flutter adopta **Clean Architecture con nomenclatura y prácticas tácticas de DDD**:
- La capa `data/` de cada feature pasa a llamarse **`infrastructure/`**: `domain / infrastructure / presentation`. El contenido es el mismo (datasources, models, mappers, repositories impl).
- Se agregan **value objects** que se validan al construirse (compartidos en `core/domain/`, propios en `domain/value_objects/` de cada feature) y **entidades con comportamiento**.
- El **backend no cambia**: sigue con la arquitectura modular natural de NestJS, como pide el requerimiento.

## Cambios v0.2 → v0.3

Surgen de comparar la estructura con [flutter-cinemapedia](https://github.com/Klerith/flutter-cinemapedia/tree/fin-seccion-18/lib), organizada por capa global. Se mantiene la organización por feature y se incorporan cuatro reglas en §2:
- Entidades sin anotaciones de persistencia ni serialización (en Cinemapedia, `Movie` depende de Isar).
- Contratos de datasource en `data/`, no en `domain/`, y ningún repositorio que solo reenvíe llamadas.
- Un barrel por feature con su API pública; sin barrels por carpeta.
- `static const name` en cada página para navegar con `goNamed`, y subcarpetas de models por fuente externa.

## Cambios v0.1 → v0.2

**Inconsistencias corregidas**
- `Order.idempotencyKey` + `@@unique([customerId, idempotencyKey])`: la decisión existía pero faltaba el campo. La key se regenera si cambia el pedido.
- La primera migración crea el **schema completo**. El seed de la Fase 1 (courier y cupones) ya no depende de tablas de fases posteriores.
- Nuevo modelo **`Promotion`** y módulo/feature `promotions`: el Home mostraba promociones sin modelo que las respaldara.
- `home` en Flutter queda **solo con presentation**: se eliminó `get_home_feed`, que rompía la regla entre features.
- `POST /auth/logout` pasa a ser **público e idempotente** con `{ refreshToken }` en el body. Antes exigía JWT y no recibía el token que decía revocar.
- Paginación **offset** en stores y búsqueda (orden calculado), **cursor** en historial y notificaciones.

**Borrador Prisma**
- Un campo por línea (antes había líneas inválidas con varios campos), `generator`/`datasource` con extensiones, relaciones con `onDelete` explícito.
- `Store.slug` único por ciudad (`@@unique([cityId, slug])`).
- `OrderItem.variantId` y `OrderItemOption.optionValueId` como referencias débiles para reorder y restauración de stock.

**Reglas de negocio agregadas**
- Cancelación transaccional: restaura stock, libera el cupón y cancela o reembolsa el pago.
- Stock y cupones con decremento/incremento condicional (`COUPON_EXHAUSTED`, `PRODUCT_OUT_OF_STOCK`).
- Carrito:
  - `storeId` se libera al vaciarse;
  - las notas forman parte del `configurationKey`;
  - `GET /cart` devuelve `issues[]`;
  - el 409 de conflicto incluye el nombre del negocio actual.
- Reorder con `CART_NOT_EMPTY` + `replaceCart`.
- `Order.cashChangeFor` para el vuelto en efectivo.
- Delivery con `City.routeFactor` y ETA con `City.avgSpeedKmh`.
- Stores filtrados por cobertura por defecto (`includeOutOfCoverage`).
- Máquina de estados detallada por rol y alcance; `PICKED_UP` exige courier (`COURIER_NOT_ASSIGNED`).
- Búsqueda insensible a acentos (`unaccent` + `pg_trgm`).
- Auth: roles no autoasignables, JWT sin consulta a BD (con el trade-off documentado), el refresh verifica que el usuario esté activo.
- WebSocket: el token se valida en el handshake y hay reconexión con token nuevo.
- Fórmula de IGV incluido y `mocktail` para testing en Flutter.
