# Chaski — qué falta para el MVP

Estado al 2026-09-24. Complementa [ARQUITECTURA.md](ARQUITECTURA.md) (v0.5).

**En corto:** la app cubre todo el flujo del cliente, pero fuera del catálogo corre con datos de demo. El backend tiene la Fase 1 (auth por OTP, catálogo, búsqueda, discovery). Lo que bloquea usar la app contra la API real es, en orden:

1. Los endpoints de **cupones y pedidos**, que la app ya llama.
2. Alguien que **avance el estado del pedido** (merchant y courier).
3. Un **proveedor de SMS** real.
4. El **deploy**.

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Onboarding, login OTP, home, búsqueda, negocio, producto, bolsa, checkout (propina, programado, cupón, vuelto), seguimiento, historial, calificación, favoritos, direcciones, avisos, perfil | Ubicación real, avisos y direcciones contra la API, editar perfil |
| Backend (`backend/`) | Auth OTP + refresh rotativo, `/users/me`, catálogo, search, discovery, cupones, pedidos, **operación de negocio y repartidor**, cancelación, seed de Espinar, 47 unit + 57 e2e | Avisos, direcciones, CRUD de catálogo, SMS real |
| Infra | `docker-compose.yml` con Postgres para desarrollo | CI, Dockerfile de la API, hosting, base administrada |
| Repo | Backend, CI y docs commiteados en la rama `feat/backend-fase-1` (sin push) | 4 archivos de mobile con cambios propios sin commitear |

## Backend

### ~~Endpoints que la app ya consume y no existen~~ (hecho)

Contrato exacto en `mobile/lib/features/cart/infrastructure/datasources/coupon_remote_data_source.dart` y `mobile/lib/features/orders/infrastructure/` (`OrderJson` y el datasource fake).

| Endpoint | Qué hace | Errores que espera la app |
|---|---|---|
| `POST /coupons/validate` | `{ code, storeId, subtotal }` → `{ code, discount, label }` | `COUPON_INVALID`, `COUPON_MIN_NOT_REACHED` (422) |
| `POST /orders` | Recibe los ítems de la bolsa local, recalcula precios, fee, descuento y total; guarda snapshots, stock condicional y cupón | `STORE_CLOSED`, `PRODUCT_UNAVAILABLE` (409), `MIN_ORDER_NOT_REACHED` (422) |
| `GET /orders?limit=30` | Historial del usuario → `{ items }` | — |
| `GET /orders/:id` | Detalle; la app lo consulta cada 8 s para el seguimiento | 404 si no es suyo |
| `POST /orders/:id/rating` | `{ rating, comment }` → pedido actualizado; recalcula `Store.ratingAvg` | solo si está `DELIVERED` |

Además, para que funcionen bien:

- **Idempotencia:** la app no envía `Idempotency-Key` en `POST /orders`, así que un doble tap o un reintento de red crea dos pedidos. El schema ya tiene `@@unique([customerId, idempotencyKey])`; falta enviarlo desde la app.
- **Pedidos programados:** si el negocio está cerrado, se acepta cuando `scheduledFor` cae dentro de su horario (el fake ya lo hace).
- **Popularidad:** `Store.popularityScore` es un dato fijo del seed; debería calcularse con los pedidos recientes.

### Operación de pedidos (hecho vía API; falta el panel)

Ya existen `/merchant/*`, `/courier/*` y `POST /orders/:id/cancel`, con la máquina de estados, cancelación con restauración de stock y cupón, y pausa del negocio. Se opera desde Swagger con los usuarios del seed (ver `backend/README.md`). Falta: botón de cancelar en la app, CRUD de catálogo y los paneles.

| Pieza | Mínimo para el MVP |
|---|---|
| Máquina de estados | `RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED`, con transiciones permitidas por rol (§8 del doc) |
| Merchant | Ver los pedidos de su negocio, confirmar, preparar, marcar listo, cancelar con motivo, pausar el negocio (`isAcceptingOrders`) |
| Courier | Ver los pedidos listos, aceptar (→ `COURIER_ASSIGNED`), en camino, entregado |
| Cancelación | Restaura stock y cupón, cancela el pago, guarda motivo y rol. La app no tiene botón de cancelar; hoy solo muestra el estado |
| Catálogo | No hay CRUD de negocios, productos, horarios ni promociones: todo sale del seed |

Para empezar alcanza con operar vía Swagger. Un panel web de merchant/admin y una app de courier vienen después.

### Otros módulos pendientes

| Módulo | Estado en la app | Endpoint sugerido |
|---|---|---|
| Avisos | Repositorio fake en memoria | `GET /notifications`, `POST /notifications/read-all`, generados al cambiar el estado del pedido |
| Direcciones | Guardadas en el dispositivo | `GET/POST/PATCH/DELETE /users/me/addresses` (la tabla `Address` ya existe) |
| Favoritos | Guardados en el dispositivo | Opcional: sincronizar para que se conserven al cambiar de teléfono |

## App móvil

| Pendiente | Detalle |
|---|---|
| Ubicación real | `CurrentDeliveryLocation` está fijo en el centro de Espinar. No hay GPS, ni mapa, ni geocodificación (no hay dependencia de mapas en `pubspec.yaml`). El formulario de dirección parte del punto actual |
| Enviar `lat`/`lng` | `/stores/:id` y `/products/:id` los aceptan, pero la app no los envía, así que el fee se calcula desde el centro de la ciudad |
| `Idempotency-Key` | Generarlo al abrir el checkout y regenerarlo si cambia el pedido (§8 del doc) |
| Editar perfil | El botón dice "Muy pronto"; `PATCH /users/me` ya existe |
| Avisos reales y push | Hoy son datos de prueba; push (FCM) va con el módulo de avisos |
| Seguimiento | Consulta cada 8 s. Alcanza para el MVP; WebSocket después |
| Android | El `AndroidManifest.xml` de `main` no declara `INTERNET` (solo debug/profile lo tienen), así que un build de release no llega a la API. Además, `http://10.0.2.2` necesita permitir tráfico sin TLS en debug. **Verificar** en un dispositivo |
| Host de la API | `env/dev.json` usa `10.0.2.2` (solo el emulador de Android). Un teléfono físico o iOS necesita la IP de la máquina o un túnel |

## Producción, calidad y seguridad

| Tema | Falta |
|---|---|
| SMS | Sin proveedor no se puede entrar en producción: el código solo va al log. Implementar `SmsSender` con un proveedor que entregue en Perú |
| Deploy | Dockerfile de la API, hosting, Postgres administrado, `prisma migrate deploy` al arrancar, variables de producción, HTTPS |
| CI | No hay `.github/workflows`. Mínimo: lint + unit + e2e del backend (con servicio Postgres) y `flutter analyze` + `flutter test` |
| Pagos | Hoy Yape, Plin, tarjeta y efectivo se pagan **al recibir**, así que el MVP no necesita pasarela. Pago online (Culqi / Mercado Pago) sigue en la Fase 4 |
| Imágenes | Todo usa placeholders de loremflickr. Falta subir y servir fotos reales (storage + CDN) |
| Limpieza de datos | Los `OtpChallenge` y `RefreshToken` vencidos se acumulan; falta un job que los borre |
| Secretos | El HMAC del OTP reutiliza `JWT_ACCESS_SECRET`; conviene un `OTP_SECRET` propio para poder rotarlos por separado |
| Rate limit | El throttler guarda en memoria: vale para una instancia; con varias hace falta Redis |
| Observabilidad | Solo logs JSON con `requestId`. Errores (Sentry) y métricas después del lanzamiento |
| Legal | Se guardan celulares y direcciones: faltan política de privacidad y términos (Ley 29733 de protección de datos personales) |

## Plan sugerido

Esfuerzos aproximados, para una persona.

| # | Trabajo | Esfuerzo | Desbloquea |
|---|---|---|---|
| 1 | ✅ Commitear lo actual + CI básica | 0.5 día | Trabajar sobre una base segura |
| 2 | ✅ Backend: cupones + pedidos (crear, listar, detalle, calificar) con e2e | 2–3 días | Comprar contra la API real |
| 3 | ✅ App: `Idempotency-Key`, `lat`/`lng`, permisos y host de Android | 0.5 día | Probar en un dispositivo |
| 4 | ✅ Máquina de estados + endpoints de merchant y courier + cancelación | 2 días | Que un pedido llegue a `DELIVERED` |
| 5 | Proveedor de SMS | 1 día | Login en producción |
| 6 | Deploy (Dockerfile, hosting, base, HTTPS) | 1–2 días | Piloto con usuarios reales |
| 7 | Ubicación real: GPS, mapa, sincronizar direcciones | 3–4 días | Fee y cobertura correctos |
| 8 | Avisos in-app + push | 3 días | Seguimiento sin abrir la app |
| 9 | Panel de merchant/admin y CRUD de catálogo | 1–2 semanas | Sumar negocios sin tocar el seed |

Con los pasos 1 a 6 se puede hacer un piloto en Espinar operando a mano (merchant y courier vía Swagger o con alguien del equipo). Los pasos 7 a 9 lo vuelven sostenible.
