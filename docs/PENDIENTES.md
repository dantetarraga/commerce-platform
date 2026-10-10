# Apamuy — qué falta para el MVP

Estado al 2026-10-09. Complementa [ARQUITECTURA.md](ARQUITECTURA.md), [OPERACION.md](OPERACION.md) (cómo se opera con negocios y repartidores) y [PANEL_WEB.md](PANEL_WEB.md) (panel Admin y Portal Socios).

**En corto:** el ciclo completo de un pedido funciona en las tres piezas: app del cliente, app Apamuy Socios (negocio y repartidor) y panel web (Admin y Portal Socios). Hay push, tiempo real por WebSocket, ubicación del repartidor, zona de reparto por ciudad y cancelación automática a los 8 minutos si el negocio no responde. Para lanzar el piloto faltan:

1. **Cuentas y llaves**: Railway, Twilio, dominio, la llave de subida a Google Play y la cuenta de servicio de Firebase en Railway. El código para todo eso ya está.
2. **Fotos reales y sesión web en cookie** (ver §2), antes de abrir el Portal Socios a negocios reales.
3. **Google Play**: declarar `https://<dominio>/privacy` y `https://<dominio>/account-deletion`.
4. Fuera del código: **revisión legal** de términos y privacidad, y definir la **comisión** de Apamuy (OPERACION §4).

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Flujo completo del cliente contra la API o en modo demo. Dirección con mapa, GPS y pin; zona de reparto; seguimiento en vivo con la moto en el mapa; push; eliminar la cuenta. Solo contraentrega. **Apamuy Socios** (flavor `partner`): negocio y repartidor en vivo, alarma con la app cerrada, ruta en Google Maps. Versión release probada (firma configurable, reglas de R8) | Mapa en iOS, ubicación del repartidor con la app cerrada |
| Backend (`backend/`) | Auth OTP, catálogo, pedidos, operación de negocio y repartidor, cancelación (manual y automática), avisos in-app y push (FCM), direcciones, eliminar la cuenta, WebSocket en `/ws`. Admin: socios, catálogo, marketing, ciudades, pedidos en vivo, caja. Portal Socios: catálogo propio, reportes y rendición | Imágenes, cookie httpOnly para la web |
| Web (`web/`) | Landing con `/privacy`, `/terms` y `/account-deletion`. Admin: métricas, usuarios, pedidos en vivo, socios, catálogo, marketing, ciudades, caja. Portal Socios: inicio del día, mi tienda, menú, reportes, rendición | Subida de fotos, editor de variantes, mapa de repartidores |
| Infra | Postgres de desarrollo (`docker-compose.yml`), CI (backend, web, imagen Docker, APK release de ambas apps), Dockerfile e infraestructura de Railway en `.railway/railway.ts` | Crear el proyecto en Railway; secretos de Firebase y de la llave en el CI; imagen más liviana (~800 MB); Redis con más de una instancia |

## 1. Bloquea el lanzamiento

| Pendiente | Detalle |
|---|---|
| Programar pedidos | ✅ El backend calcula las horas (`GET /stores/:id/delivery-slots`) con el horario del negocio y la hora de la ciudad, con la misma regla que valida el pedido: el día completo en que atiende y los días cerrados desactivados |
| Firma y publicación | ✅ Firma con `android/key.properties`, reglas de R8 y el sonido de la alarma conservado (`res/raw/keep.xml`; sin él la alarma fallaba en release). Falta crear la llave de subida, `env/prod.json` con la URL HTTPS y la ficha en Play Console (ver `mobile/README.md`) |
| Firebase | ✅ Push hecho y probado en debug y release. Falta `FCM_SERVICE_ACCOUNT_BASE64` en Railway y el secreto `GOOGLE_SERVICES_JSON_BASE64` en el CI |
| Privacidad y eliminación | ✅ `/privacy`, `/terms` y `/account-deletion` en la web, con el mismo texto que las apps (un test avisa si se separan). Falta declararlas en Google Play |
| Twilio y Railway | Crear las cuentas. El código ya está listo (`SMS_PROVIDER=twilio`, `.railway/railway.ts`) |
| Legal | Términos y privacidad en borrador (Ley 29733), ya al día con push y eliminación de cuenta. Falta la revisión de un abogado y completar los datos entre corchetes |

## 2. Para operar bien

| Pendiente | Detalle |
|---|---|
| Usuarios y métricas del admin | ✅ **Usuarios** (`/admin/users`): lista con búsqueda y filtros, ficha con pedidos, gasto, sesiones y desempeño de socio (30 días); bloquear y desbloquear, reactivar a un socio suspendido, cerrar sesiones, dar o quitar el acceso de admin, con historial de quién hizo cada cambio. **Inicio**: tablero calculado en el backend (`admin/analytics`) con pedidos, ventas, clientes nuevos, horas pico, tiempos, cancelaciones, negocios, productos, repartidores, pagos y cupones |
| Fotos reales | Todo usa placeholders de loremflickr. Falta storage (S3/R2) con URLs prefirmadas, CDN y la subida en el panel y el Portal Socios |
| Sesión web en cookie | El refresh token del panel vive en `localStorage`. Pasarlo a cookie httpOnly + CORS del dominio antes de abrir el Portal Socios a negocios reales |
| Cobertura desde `GET /cities` | ✅ La app lee el centro y el radio de la ciudad al abrir (`core/config/city_area.dart`), los guarda para usarlos sin red y valida con ellos las direcciones: un cambio en Ciudades llega sin publicar otra versión |
| Variantes y opciones | El panel las muestra pero no las edita ("Grande", "Con papas"); hoy se editan por Swagger |
| Comisión y liquidaciones | Rendición muestra lo vendido y lo cobrado; falta decidir la comisión para liquidar a los negocios |
| Mapa de repartidores | La ubicación ya llega al backend; falta dibujarla en Pedidos en vivo |
| Ubicación con la app cerrada | El repartidor solo comparte su posición con Socios abierta. Requiere un servicio en primer plano en Android |
| Mapa en iOS | Falta la key de Maps SDK for iOS; mientras, el plano dibujado |

## 3. Después del piloto

| Pendiente | Detalle |
|---|---|
| iOS | Push sin configurar (falta `GoogleService-Info.plist` y la llave APNs) y la key de mapas. Solo si se publica en App Store |
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
| 1–12 | ✅ Base, pedidos, SMS, deploy preparado, avisos, direcciones, ubicación, Apamuy Socios, tiempo real, panel web (Admin y Portal Socios), cancelación automática | — | Piloto operando |
| 13 | ✅ Push con alarma del negocio, eliminar la cuenta, logo nuevo | — | Que ningún pedido quede sin atender |
| 14 | ✅ Privacidad y términos en la web, firma y versión release probada | — | Publicar en Google Play |
| 15 | ✅ Programar pedidos con el horario del negocio | — | Pedidos programados que no fallen |
| 16 | ✅ Usuarios y métricas del admin | — | Gestionar socios y clientes, y decidir con datos |
| 17 | Fotos reales y sesión web en cookie | 3–4 días | Abrir el Portal Socios a negocios |
| 18 | Editor de variantes, mapa de repartidores (cobertura desde `GET /cities` ✅) | 2 días | Operación sin parches |
