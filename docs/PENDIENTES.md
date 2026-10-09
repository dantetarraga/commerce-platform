# Apamuy — qué falta para el MVP

Estado al 2026-10-09. Complementa [ARQUITECTURA.md](ARQUITECTURA.md), [OPERACION.md](OPERACION.md) (cómo se opera con negocios y repartidores) y [PANEL_WEB.md](PANEL_WEB.md) (panel Admin y Portal Socios).

**En corto:** el ciclo completo de un pedido funciona en las tres piezas: app del cliente, app Apamuy Socios (negocio y repartidor) y panel web (Admin y Portal Socios). Hay tiempo real por WebSocket, ubicación del repartidor, zona de reparto por ciudad y cancelación automática a los 8 minutos si el negocio no responde. Para lanzar el piloto faltan:

1. **Firebase**: proyecto creado y probado en local (alarma con Socios cerrada). Falta cargar `PUSH_PROVIDER=fcm` y `FCM_SERVICE_ACCOUNT_BASE64` en Railway y `google-services.json` en el CI que arma los APK.
2. **Google Play**: declarar `https://<dominio>/account-deletion` como URL de eliminación de cuentas.
3. Fuera del código: cuentas de **Twilio** y **Railway** (guía en `backend/README.md`), **revisión legal** de términos y privacidad, y definir la **comisión** de Apamuy (OPERACION §4).

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Flujo completo del cliente contra la API o en modo demo. Dirección con mapa, GPS y pin; zona de reparto; seguimiento en vivo con la moto en el mapa. Solo contraentrega. **Apamuy Socios** (flavor `partner`): negocio y repartidor en vivo, ruta en Google Maps | Leer la cobertura de `GET /cities` (hoy fija en `core/config/city.dart`), mapa en iOS, ubicación del repartidor con la app cerrada |
| Backend (`backend/`) | Auth OTP, catálogo, pedidos, operación de negocio y repartidor, cancelación (manual y automática), avisos in-app, direcciones, WebSocket en `/ws`. Admin: socios, catálogo, marketing, ciudades, pedidos en vivo, caja. Portal Socios: catálogo propio, reportes y rendición | Imágenes, cookie httpOnly para la web |
| Web (`web/`) | Admin: pedidos en vivo, socios, catálogo, marketing, ciudades, caja. Portal Socios: inicio del día, mi tienda, menú, reportes, rendición. Suspense, sesión entre pestañas, errores con código de soporte | Subida de fotos, editor de variantes y opciones, mapa de repartidores |
| Infra | Postgres de desarrollo (`docker-compose.yml`), CI (backend, mobile, imagen Docker, APK de ambas apps), Dockerfile y `railway.toml` | Crear el proyecto en Railway; imagen más liviana (~800 MB); Redis cuando haya más de una instancia |

## 1. Bloquea el lanzamiento

| Pendiente | Detalle |
|---|---|
| Firebase | ✅ Push hecho: avisos al cliente, alarma del negocio con la app cerrada, pedidos listos a los repartidores. Proyecto `apamuy-app` listo y probado en local; falta la cuenta de servicio en Railway y `google-services.json` en el CI |
| Eliminar la cuenta | ✅ App del cliente (Tú → Eliminar mi cuenta), `DELETE /users/me` y `/account-deletion` en la web. Los socios piden la baja a Apamuy. Falta declarar la URL en Google Play |
| Twilio y Railway | Crear las cuentas. El código ya está listo (`SMS_PROVIDER=twilio`, `railway.toml`) |
| Legal | Términos y privacidad en borrador dentro de las apps (Ley 29733). Falta la revisión de un abogado |

## 2. Para operar bien

| Pendiente | Detalle |
|---|---|
| Fotos reales | Todo usa placeholders de loremflickr. Falta storage (S3/R2) con URLs prefirmadas, CDN y la subida en el panel y el Portal Socios |
| Sesión web en cookie | El refresh token del panel vive en `localStorage`. Pasarlo a cookie httpOnly + CORS del dominio antes de abrir el Portal Socios a negocios reales |
| Variantes y opciones | El panel las muestra pero no las edita ("Grande", "Con papas"); hoy se editan por Swagger |
| Cobertura en la app | `cityCoverageKm` está fijo en la app; ahora que Ciudades se edita desde el panel, debe leerse de `GET /cities` |
| Comisión y liquidaciones | Rendición muestra lo vendido y lo cobrado; falta decidir la comisión para liquidar a los negocios |
| Mapa de repartidores | La ubicación ya llega al backend; falta dibujarla en Pedidos en vivo |
| Ubicación con la app cerrada | El repartidor solo comparte su posición con Socios abierta. Requiere un servicio en primer plano en Android |
| Mapa en iOS | Falta la key de Maps SDK for iOS; mientras, el plano dibujado |

## 3. Después del piloto

| Pendiente | Detalle |
|---|---|
| Reseñas | Los clientes califican, pero ni el admin ni el negocio las ven |
| Soporte | Botón de ayuda o WhatsApp dentro de la app (hoy solo en la landing) |
| Observabilidad | Logs JSON con `requestId`. Faltan Sentry y métricas |
| Escala | Rate limit y WebSocket en memoria: con varias instancias, Redis |
| Pagos en línea | Culqi o Mercado Pago (Fase 4). Hoy efectivo, Yape y Plin al recibir |
| Más adelante | Favoritos sincronizados, promociones propias del negocio, solicitud de afiliación con documentos |

## Plan

Esfuerzos aproximados, para una persona.

| # | Trabajo | Esfuerzo | Desbloquea |
|---|---|---|---|
| 1–11 | ✅ Base, pedidos, estados, SMS, deploy preparado, avisos, direcciones, ubicación, Apamuy Socios, alta de socios, tiempo real | — | Piloto operando |
| 12 | ✅ Panel web: Admin (pedidos en vivo, socios, catálogo, marketing, ciudades, caja) y Portal Socios. Cancelación automática a los 8 min | — | Operar sin Swagger |
| 13 | ✅ Push con FCM y alarma del negocio con la app cerrada (falta la cuenta de servicio en Railway) | — | Que ningún pedido quede sin atender |
| 14 | ✅ Eliminar la cuenta (app, backend y página web) | — | Publicar en Google Play |
| 15 | Fotos reales y sesión web en cookie | 3–4 días | Abrir el Portal Socios a negocios |
| 16 | Cobertura desde `GET /cities`, editor de variantes, mapa de repartidores | 2–3 días | Operación sin parches |
