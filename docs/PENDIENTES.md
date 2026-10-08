# Apamuy — qué falta para el MVP

Estado al 2026-10-08. Complementa [ARQUITECTURA.md](ARQUITECTURA.md) (v0.5) y [OPERACION.md](OPERACION.md) (cómo se opera con negocios y repartidores).

**En corto:** la app y el backend ya cubren el ciclo completo de un pedido: pedir, confirmar, preparar, repartir, entregar, calificar y cancelar. Hay ubicación real (GPS y Google Maps en Android), zona de reparto validada en el backend y tiempo real por WebSocket: el cliente ve la moto en el mapa y el negocio recibe los pedidos al instante. Para un piloto en Espinar faltan tres cosas fuera del código:

1. Crear la cuenta de **Twilio**.
2. Crear el proyecto en **Railway**; la guía está en `backend/README.md`.
3. Revisar con un abogado los **términos y la privacidad** (hoy son borradores dentro de las apps).

En código, lo que sigue es el **push (FCM)** con plazo de aceptación y alarma con la app cerrada. Después, el panel admin web.

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Todo el flujo del cliente contra la API o en modo demo. Dirección con mapa de Google, GPS y pin (llena la calle sola y vuela a la calle escrita), zona de reparto de 6 km, referencia obligatoria. Seguimiento en vivo por WebSocket con la moto en el mapa. Solo contraentrega. **Apamuy Socios** (flavor `partner`): Negocio y Repartidor en vivo, el repartidor comparte su ubicación y abre la ruta en Google Maps. Arranque con la moto, carga con tres puntos. 289 tests | Push, mapa en iOS (falta su key) |
| Backend (`backend/`) | Auth OTP con Twilio, catálogo, pedidos, operación de negocio y repartidor, cancelación, avisos, direcciones, admin (`admin/*`). Zona de reparto por ciudad (`coverageKm`). WebSocket Socket.IO en `/ws` (rooms por pedido, negocio y ciudad) y `POST /courier/me/location`. 99 unit + 103 e2e | Push, imágenes |
| Infra | Postgres de desarrollo (`docker-compose.yml`), CI (backend + mobile + imagen Docker + APK de ambas apps), Dockerfile y `railway.toml` | Crear el proyecto en Railway; imagen más liviana (~800 MB) |

## Operación de pedidos

El negocio y el repartidor operan desde **Apamuy Socios** (`/merchant/*` y `/courier/*` por debajo; contrato en [OPERACION.md](OPERACION.md) §7). Los socios se dan de alta con `admin/*` (ver [OPERACION.md](OPERACION.md) §5); el seed trae socios de demo (ver `backend/README.md`).

| Pieza | Estado |
|---|---|
| Máquina de estados | ✅ `RECEIVED → CONFIRMED → PREPARING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED`, con permisos por rol |
| Negocio | ✅ Ver sus pedidos al instante (WebSocket), avanzar, cancelar con motivo, pausar pedidos. Sigue consultando con la pantalla bloqueada para que suene la alarma |
| Repartidor | ✅ Pedidos listos de su ciudad en vivo, tomar uno (solo uno gana), en camino, entregado. Comparte su ubicación cada 10 s con la app abierta |
| Cancelación | ✅ Restaura stock y cupón, cancela el pago y avisa al cliente |
| Catálogo | ✅ El admin crea y edita negocios, horarios, secciones, productos, categorías, cupones y banners desde Swagger |
| Paneles | ✅ App **Apamuy Socios**. Faltan el push y el panel admin web |

## Tiempo real y ubicación

| Pieza | Estado |
|---|---|
| WebSocket | ✅ Socket.IO en `/ws`, token en el handshake. Los eventos solo avisan; la app vuelve a pedir por REST. Respaldo por consulta: 30 s con conexión, 8–10 s sin ella. Una sola instancia (con varias, adapter de Redis) |
| Ubicación del repartidor | ✅ Solo la última posición. El cliente la ve mientras el pedido va en camino y si tiene menos de 2 minutos. Con la app de Socios cerrada no se envía (llega con el push: servicio en primer plano) |
| Mapas | ✅ Google Maps en Android (key en `android/local.properties`, nunca en git). iOS, web y tests usan el plano o el recorrido ilustrados |
| Geocodificación | ✅ La del teléfono (sin key ni costo). En Yauri puede no encontrar calles: el pin manda sobre el texto |

## Backend

| Pendiente | Detalle |
|---|---|
| Push (FCM) | Los avisos in-app ya se crean en cada cambio de estado; falta enviarlos como push (tabla `Device` lista) |
| Imágenes | Todo usa placeholders de loremflickr. Falta subir y servir fotos reales (storage + CDN) |
| Favoritos | Guardados en el dispositivo. Opcional: sincronizar para no perderlos al cambiar de teléfono |

## App móvil

| Pendiente | Detalle |
|---|---|
| Push | Registro del token FCM, apertura del pedido al tocar el aviso, alarma y ubicación del repartidor con la app cerrada |
| Mapa en iOS | Falta la key de Maps SDK for iOS en `AppDelegate`; hasta entonces iOS usa el plano dibujado |
| Radio de cobertura | Está fijo en la app (`core/config/city.dart`) y en el seed (6 km). Si cambia, tocar ambos o leerlo de `GET /cities` |
| Probar en un teléfono | Con `adb reverse tcp:3000 tcp:3000` y `env/dev-device.json` |

## Producción, calidad y seguridad

| Tema | Estado |
|---|---|
| SMS | ✅ Twilio (`SMS_PROVIDER=twilio`, obligatorio en producción). Falta crear la cuenta y el Messaging Service |
| Deploy | ✅ Dockerfile + `railway.toml` probados localmente. Falta crear el proyecto y separar las migraciones para achicar la imagen |
| CI | ✅ Lint, unit, e2e, build e imagen Docker del backend; `flutter analyze`, `flutter test` y APK de las dos apps |
| Pagos | Efectivo, Yape y Plin se pagan **al recibir**; tarjeta deshabilitada. Pago online (Culqi / Mercado Pago) en la Fase 4 |
| Limpieza de datos | ✅ Tarea diaria que borra códigos OTP viejos y refresh tokens vencidos |
| Rate limit | En memoria (con `TRUST_PROXY` para Railway): vale para una instancia; con varias hace falta Redis |
| Observabilidad | Logs JSON con `requestId`. Errores (Sentry) y métricas después del lanzamiento |
| Legal | Términos y privacidad en borrador dentro de las dos apps (Ley 29733). Falta la revisión legal |

## Plan

Esfuerzos aproximados, para una persona.

| # | Trabajo | Esfuerzo | Desbloquea |
|---|---|---|---|
| 1–7 | ✅ Base, pedidos, estados, SMS, deploy preparado, avisos y direcciones | — | Piloto operando a mano |
| 8 | ✅ Ubicación real: GPS, mapa, geocodificación del teléfono y zona de reparto | 3–4 días | Fee y cobertura correctos |
| 9 | ✅ App Apamuy Socios: Negocio y Repartidor con cobro contraentrega | 2–3 semanas | Operar sin Swagger |
| 10 | ✅ Alta y suspensión de socios por admin | 1–2 días | Piloto con socios reales |
| 11 | ✅ Tiempo real: WebSocket, moto en el mapa, ubicación del repartidor | 3 días | Seguimiento en vivo |
| 12 | Push con FCM, alarma y ubicación con la app cerrada, plazo de aceptación | 4–5 días | Que ningún pedido quede sin atender |
| 13 | ✅ CRUD de catálogo (`admin/*`). Falta el panel admin web | 1–2 semanas | Sumar negocios sin tocar el seed |
