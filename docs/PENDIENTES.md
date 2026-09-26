# Chaski — qué falta para el MVP

Estado al 2026-09-26. Complementa [ARQUITECTURA.md](ARQUITECTURA.md) (v0.5) y [OPERACION.md](OPERACION.md) (cómo se opera con negocios y repartidores).

**En corto:** la app y el backend ya cubren el ciclo completo de un pedido: pedir, confirmar, preparar, repartir, entregar, calificar y cancelar. También hay avisos in-app y direcciones sincronizadas. Para un piloto en Espinar faltan tres cosas fuera del código:

1. Crear la cuenta de **Twilio**.
2. Crear el proyecto en **Railway**; la guía está en `backend/README.md`.
3. Hacer **push** de `main`: los commits de Chaski Socios están solo en local y la CI todavía no los probó.

La **app Chaski Socios** (negocio y repartidor) ya opera pedidos contra la API. Lo que sigue en código es el alta de socios por admin y el push con plazo de aceptación. Después, la ubicación real y el panel admin web.

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Todo el flujo del cliente contra la API o en modo demo. `Idempotency-Key`, ubicación en detalle de negocio y producto, avisos y direcciones reales, cancelar pedido, Android e iOS listos para la API local. Solo contraentrega (sin tarjeta). **Chaski Socios** (flavor `partner`): modos Negocio y Repartidor con alarma. 158 tests | Ubicación real (GPS/mapa), editar perfil, push |
| Backend (`backend/`) | Auth OTP con Twilio + refresh rotativo, `/users/me`, catálogo, búsqueda, discovery, cupones, pedidos, operación del negocio y del repartidor, cancelación, avisos, direcciones, limpieza diaria. API de socios (`merchant/*`, `courier/*`): aceptar con tiempo, productos, resúmenes, disponibilidad del repartidor y registro del cobro; 76 unit + 73 e2e | Alta de socios por admin, CRUD de catálogo, push, imágenes |
| Infra | Postgres de desarrollo (`docker-compose.yml`), CI (backend + mobile + imagen Docker + APK de ambas apps), Dockerfile y `railway.toml` | Crear el proyecto en Railway; imagen más liviana (~800 MB) |
| Repo | `feat/backend-fase-1` ya se integró a `main` y se borró. Todo commiteado | Push de `main` (los commits de Chaski Socios están solo en local) |

## Operación de pedidos

El negocio y el repartidor operan desde **Chaski Socios** (`/merchant/*` y `/courier/*` por debajo; contrato en [OPERACION.md](OPERACION.md) §7). Mientras no exista el alta por admin, los socios son los del seed (ver `backend/README.md`).

| Pieza | Estado |
|---|---|
| Máquina de estados | ✅ `RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED`, con permisos por rol |
| Negocio | ✅ Ver sus pedidos con datos del cliente, avanzar, cancelar con motivo, pausar pedidos |
| Repartidor | ✅ Pedidos listos de su ciudad, tomar uno (solo uno gana), en camino, entregado |
| Cancelación | ✅ Restaura stock y cupón, cancela el pago y avisa al cliente. La app cancela desde "Ayuda con tu pedido" |
| Catálogo | Falta el CRUD de negocios, productos, horarios y promociones: hoy todo sale del seed |
| Paneles | ✅ App **Chaski Socios**: el negocio acepta con tiempo, rechaza, marca listo, pausa y agota productos; el repartidor se conecta, toma, recoge y entrega registrando el cobro. Alarma con la app abierta. Faltan el alta de socios por admin, el push y el panel admin web |

## Backend

| Pendiente | Detalle |
|---|---|
| CRUD de catálogo | Para sumar negocios, productos, horarios y promociones sin tocar el seed |
| Push (FCM) | Los avisos in-app ya se crean en cada cambio de estado; falta enviarlos como push (tabla `Device` lista) |
| Imágenes | Todo usa placeholders de loremflickr. Falta subir y servir fotos reales (storage + CDN) |
| Favoritos | Guardados en el dispositivo. Opcional: sincronizar para no perderlos al cambiar de teléfono |
| ETA en camino | `estimatedArrival` se fija al crear el pedido; conviene recalcularlo al salir el repartidor |

## App móvil

| Pendiente | Detalle |
|---|---|
| Ubicación real | `CurrentDeliveryLocation` arranca en el centro de Espinar. No hay GPS, mapa ni geocodificación (sin dependencia de mapas en `pubspec.yaml`); el formulario de dirección parte del punto actual |
| Editar perfil | El botón dice "Muy pronto"; `PATCH /users/me` ya existe |
| Push | Registro del token FCM y apertura del pedido al tocar el aviso |
| Seguimiento | Consulta cada 8 s. Alcanza para el MVP; WebSocket después |
| Probar en un teléfono | Con `adb reverse tcp:3000 tcp:3000` y `env/dev-device.json` |

## Producción, calidad y seguridad

| Tema | Estado |
|---|---|
| SMS | ✅ Twilio (`SMS_PROVIDER=twilio`, obligatorio en producción). Falta crear la cuenta y el Messaging Service |
| Deploy | ✅ Dockerfile + `railway.toml` probados localmente. Falta crear el proyecto y separar las migraciones para achicar la imagen |
| CI | ✅ Lint, unit, e2e, build e imagen Docker del backend; `flutter analyze`, `flutter test` y APK de las dos apps. Corre al hacer push a `main` o en un PR |
| Pagos | Efectivo, Yape y Plin se pagan **al recibir**; tarjeta está deshabilitada (sin POS). El repartidor registra lo cobrado al entregar. El MVP no necesita pasarela. Pago online (Culqi / Mercado Pago) en la Fase 4 |
| Limpieza de datos | ✅ Tarea diaria que borra códigos OTP viejos y refresh tokens vencidos |
| Secretos | ✅ `OTP_SECRET` propio, distinto de `JWT_ACCESS_SECRET` |
| Rate limit | En memoria (con `TRUST_PROXY` para Railway): vale para una instancia; con varias hace falta Redis |
| Observabilidad | Logs JSON con `requestId`. Errores (Sentry) y métricas después del lanzamiento |
| Legal | Se guardan celulares y direcciones: faltan la política de privacidad y los términos (Ley 29733 de protección de datos personales) |

## Plan

Esfuerzos aproximados, para una persona.

| # | Trabajo | Esfuerzo | Desbloquea |
|---|---|---|---|
| 1 | ✅ Commit + CI básica | 0.5 día | Base segura |
| 2 | ✅ Cupones + pedidos (crear, listar, detalle, calificar) | 2–3 días | Comprar contra la API |
| 3 | ✅ App: `Idempotency-Key`, `lat`/`lng`, Android e iOS | 0.5 día | Probar en un dispositivo |
| 4 | ✅ Máquina de estados, negocio, repartidor, cancelación | 2 días | Que un pedido llegue a `DELIVERED` |
| 5 | ✅ SMS con Twilio (falta la cuenta) | 1 día | Login en producción |
| 6 | ✅ Deploy preparado para Railway (falta el proyecto) | 1–2 días | Piloto con usuarios reales |
| 7 | ✅ Avisos in-app, direcciones en la API, cancelar en la app, endurecimiento | 2 días | Seguimiento y datos entre dispositivos |
| 8 | Ubicación real: GPS, mapa y geocodificación | 3–4 días | Fee y cobertura correctos |
| 9 | ✅ App Chaski Socios: base, modo Negocio y modo Repartidor con cobro contraentrega (app + API) | 2–3 semanas | Operar sin Swagger (demo con el seed) |
| 10 | Alta y suspensión de socios por admin | 1–2 días | Piloto con socios reales |
| 11 | Push con FCM, alarma con la app cerrada y plazo de aceptación | 4–5 días | Que ningún pedido quede sin atender |
| 12 | Panel admin web y CRUD de catálogo | 1–2 semanas | Sumar negocios sin tocar el seed |

Con lo hecho hasta el paso 7 ya se puede hacer un piloto operando a mano: el negocio y el repartidor usan Swagger, o alguien del equipo lo hace por ellos. Los pasos 9 a 11 permiten la prueba con socios reales; el detalle está en [OPERACION.md](OPERACION.md).
