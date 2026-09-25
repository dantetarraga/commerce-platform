# Chaski — qué falta para el MVP

Estado al 2026-09-25. Complementa [ARQUITECTURA.md](ARQUITECTURA.md) (v0.5).

**En corto:** la app y el backend ya cubren el ciclo completo de un pedido: pedir, confirmar, preparar, repartir, entregar, calificar y cancelar. También hay avisos in-app y direcciones sincronizadas. Para un piloto en Espinar faltan tres cosas fuera del código:

1. Crear la cuenta de **Twilio**.
2. Crear el proyecto en **Railway**; la guía está en `backend/README.md`.
3. Hacer **push** de la rama `feat/backend-fase-1` para que corra la CI.

Lo que sigue en código es la ubicación real, el push y el panel del negocio.

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Todo el flujo del cliente contra la API o en modo demo. `Idempotency-Key`, ubicación en detalle de negocio y producto, avisos y direcciones reales, cancelar pedido, Android e iOS listos para la API local; 139 tests | Ubicación real (GPS/mapa), editar perfil, push |
| Backend (`backend/`) | Auth OTP con Twilio + refresh rotativo, `/users/me`, catálogo, búsqueda, discovery, cupones, pedidos, operación del negocio y del repartidor, cancelación, avisos, direcciones, limpieza diaria; 62 unit + 62 e2e | CRUD de catálogo, push, imágenes |
| Infra | Postgres de desarrollo (`docker-compose.yml`), CI (backend + mobile + imagen Docker), Dockerfile y `railway.toml` | Crear el proyecto en Railway; imagen más liviana (~800 MB) |
| Repo | Todo commiteado en `feat/backend-fase-1` (sin push) | 4 archivos de mobile con cambios propios sin commitear |

## Operación de pedidos

Se opera por API: `/merchant/*` para el negocio y `/courier/*` para el repartidor, con los usuarios del seed desde Swagger (ver `backend/README.md`).

| Pieza | Estado |
|---|---|
| Máquina de estados | ✅ `RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED`, con permisos por rol |
| Negocio | ✅ Ver sus pedidos con datos del cliente, avanzar, cancelar con motivo, pausar pedidos |
| Repartidor | ✅ Pedidos listos de su ciudad, tomar uno (solo uno gana), en camino, entregado |
| Cancelación | ✅ Restaura stock y cupón, cancela el pago y avisa al cliente. La app cancela desde "Ayuda con tu pedido" |
| Catálogo | Falta el CRUD de negocios, productos, horarios y promociones: hoy todo sale del seed |
| Paneles | Faltan un panel web para negocio y admin, y una app para el repartidor |

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
| CI | ✅ Lint, unit, e2e, build e imagen Docker del backend; `flutter analyze` + `flutter test`. Corre al hacer push |
| Pagos | Yape, Plin, tarjeta y efectivo se pagan **al recibir**: el MVP no necesita pasarela. Pago online (Culqi / Mercado Pago) en la Fase 4 |
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
| 9 | Push con FCM | 2 días | Enterarse sin abrir la app |
| 10 | Panel de negocio/admin y CRUD de catálogo | 1–2 semanas | Sumar negocios sin tocar el seed |

Con lo hecho hasta el paso 7 ya se puede hacer un piloto operando a mano: el negocio y el repartidor usan Swagger, o alguien del equipo lo hace por ellos. Los pasos 8 a 10 lo vuelven sostenible.
