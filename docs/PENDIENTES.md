# Apamuy — qué falta para el MVP

Estado al 2026-10-11. Complementa [ARQUITECTURA.md](ARQUITECTURA.md), [OPERACION.md](OPERACION.md) (cómo se opera con negocios y repartidores) y [PANEL_WEB.md](PANEL_WEB.md) (panel Admin y Portal Socios).

**En corto:** el ciclo completo de un pedido funciona en las tres piezas: app del cliente, app Apamuy Socios (negocio y repartidor) y panel web (Admin y Portal Socios). Hay push, tiempo real por WebSocket, ubicación del repartidor, zona de reparto por ciudad y cancelación automática a los 8 minutos si el negocio no responde. Para lanzar el piloto faltan:

1. **Cuentas y llaves**: Railway, Twilio, dominio, el bucket de fotos en Cloudflare R2, la llave de subida a Google Play y la cuenta de servicio de Firebase en Railway. El código para todo eso ya está.
2. Cargar las fotos reales (ver §2) antes de abrir el Portal Socios a negocios reales.
3. **Google Play**: declarar `https://<dominio>/privacy` y `https://<dominio>/account-deletion`.
4. Fuera del código: **revisión legal** de términos y privacidad, y definir la **comisión** de Apamuy (OPERACION §4).

## Estado actual

| Parte | Listo | Falta |
|---|---|---|
| App (`mobile/`) | Flujo completo del cliente contra la API o en modo demo. Dirección con mapa, GPS y pin; zona de reparto; seguimiento en vivo con la moto en el mapa; push; eliminar la cuenta. Solo contraentrega. **Apamuy Socios** (flavor `partner`): negocio y repartidor en vivo; el negocio gestiona su carta (productos con foto de la cámara, secciones e importación desde Excel o CSV); alarma con la app cerrada, ruta en Google Maps. Versión release probada (firma configurable, reglas de R8) | Mapa en iOS |
| Backend (`backend/`) | Auth OTP, catálogo, pedidos, operación de negocio y repartidor, cancelación (manual y automática), avisos in-app y push (FCM), direcciones, eliminar la cuenta, WebSocket en `/ws`. Admin: socios, catálogo, marketing, ciudades, pedidos en vivo, caja. Portal Socios: catálogo propio, reportes y rendición. Subida de fotos a R2 con URL firmada e importación de la carta desde Excel o CSV | Borrar fotos reemplazadas |
| Web (`web/`) | Landing con `/privacy`, `/terms` y `/account-deletion`. Admin: métricas, usuarios, pedidos en vivo, socios, catálogo, marketing, ciudades, caja. Portal Socios: inicio del día, mi tienda, menú (con subida de fotos e importación desde Excel o CSV), reportes, rendición | Ordenar productos arrastrando |
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
| Fotos reales | ✅ **Subida**: `POST /uploads/images` firma un `PUT` directo a Cloudflare R2 (sin costo de salida). El panel achica la foto a WebP de 1600 px antes de subirla. Funciona en productos, logo, portada, banners e íconos de categoría (`backend/README.md`, "Fotos en Cloudflare R2"). Falta: crear el bucket con su dominio (`img.apamuy.pe`) y su CORS; cambiar las fotos de loremflickr del seed por fotos reales; borrar del bucket la foto anterior al reemplazarla, y las que se suben pero no se guardan (un cron semanal). La app Socios ya sube fotos desde la cámara o la galería |
| Carga masiva de la carta | ✅ **Excel o CSV**, en el panel (Menú → *Importar Excel o CSV*) y en la app Socios (Carta → *Importar Excel*), con el mismo formato y el mismo endpoint: plantilla descargable, revisión sin guardar con el error de cada fila, y luego todo se guarda en una transacción. Un producto con el mismo nombre se actualiza y las secciones que faltan se crean. Hasta 500 filas. No importa variantes ni opciones |
| Carta desde una foto | El dueño fotografía su carta impresa o su pizarra y un modelo con visión (Claude) arma el borrador: secciones, productos, precios y descripciones. Se revisa en la misma vista de la importación (`dryRun`) y se guarda con `products/import`, así que solo falta la extracción. Es lo que más acelera el alta de restaurantes |
| Sesión web en cookie | ✅ El panel manda `X-Apamuy-Client: web` y la API le entrega el refresh token en la cookie httpOnly `apamuy_rt` (solo viaja a `/api/v1/auth`); las apps lo siguen recibiendo en el cuerpo. Si panel y API quedan en sitios distintos (dos `*.up.railway.app`), poner `AUTH_COOKIE_SAMESITE=none` y el dominio del panel en `CORS_ORIGINS` |
| Cobertura desde `GET /cities` | ✅ La app lee el centro y el radio de la ciudad al abrir (`core/config/city_area.dart`), los guarda para usarlos sin red y valida con ellos las direcciones: un cambio en Ciudades llega sin publicar otra versión |
| Variantes y opciones | ✅ En el panel (admin y Portal Socios): variantes con su precio y grupos de opciones con mínimo, máximo y lo que suma cada una. La app Socios las muestra pero aún no las edita |
| Carta en la app Socios | ✅ Crear, editar y quitar productos (foto con la cámara o la galería, precio, descripción, sección, stock), secciones ordenadas arrastrando (`PUT merchant/catalog/stores/:id/sections/order`), importación desde Excel o CSV con revisión del precio de antes y el nuevo, filtro «sin foto» y foto rápida desde la lista, una pantalla de inicio para la carta vacía, edición rápida (precio, disponible, stock) al tocar un producto, elegir varios con un toque largo (agotar, reponer, mover de sección), «Deshacer» al agotar, aviso al salir con cambios sin guardar, recorte cuadrado de la foto (`image_cropper`), avance de la subida con «Reintentar», resaltado de lo importado y lista y edición lado a lado en tablet (`features/merchant_catalog`). Faltan ordenar productos arrastrando (también en la web), editar variantes y compartir la plantilla por WhatsApp (pide `share_plus`) |
| Comisión y liquidaciones | Rendición muestra lo vendido y lo cobrado; falta decidir la comisión para liquidar a los negocios |
| Mapa de repartidores | ✅ En Pedidos en vivo (`GET /admin/orders/couriers` y el evento `admin.courier.moved`): cada repartidor conectado con su pedido, «sin señal» tras 5 minutos, y la misma información en una lista. **Pendiente:** una key web propia (Maps JavaScript API, restringida al dominio del panel) y un Map ID en `VITE_GOOGLE_MAPS_API_KEY` y `VITE_GOOGLE_MAPS_MAP_ID`. Sin ellas se ve solo la lista. Trae 10 000 cargas gratis al mes; ponerle un límite diario en Google Cloud |
| Ubicación con la app de fondo | ✅ Con un pedido en curso, Socios sigue mandando la ubicación de fondo o con la pantalla apagada (servicio en primer plano de geolocator, con aviso fijo). Con la app cerrada del todo no. En Play Console hay que declarar el servicio en primer plano de ubicación (con video) |
| Mapa en iOS | Falta la key de Maps SDK for iOS; mientras, el plano dibujado |

## 2b. Revisión del 2026-10-11

Corregido: el seed de demo se niega a correr contra una base que no sea local y el primer admin de producción se crea con `npm run db:bootstrap`; el repartidor ya no ve celular, dirección exacta ni apellido del cliente antes de aceptar; un release sin env no sale como demo (`USE_FAKE_DATA` es `false` por defecto y un release exige `https`; el CI arma APK de demo a propósito); el reintento tras renovar la sesión ya no puede colgar la app; sin señal no se cierra la sesión (el backend tolera 30 s repetir una rotación cuya respuesta se perdió) y la app abre con la última cuenta vista; la ayuda del pedido se envía por el WhatsApp de soporte (`SUPPORT_WHATSAPP`) en vez de fingir el envío; Pedidos en vivo avisa con la pestaña de fondo (título, sonido y notificación del navegador) y el tiempo real se reconecta solo; el cuerpo JSON acepta hasta 1 MB (la importación de 500 filas).

Falta, por prioridad:

| Pendiente | Detalle |
|---|---|
| Total que ve el cliente | Se calcula en el teléfono; falta `POST /checkout/quote` (ARQUITECTURA §1) para mostrar el que cobrará el repartidor |
| Cupones | El de un solo uso se puede canjear dos veces en paralelo; borrar la cuenta y registrarse da otra vez el de bienvenida |
| Abuso | Sin tope de pedidos activos por cliente; OTP sin freno global (gasto en Twilio); el límite por IP puede bloquear a un pueblo entero (CGNAT) |
| Repartidor | Sin salida para «el cliente no estaba» ni prueba de entrega; el cliente no puede llamarlo aunque se le pide pagarle por Yape |
| Bloquear o quitar un rol | No es inmediato (JWT de 15 min) y el WebSocket del admin no vence |
| Pedidos trabados | Nadie atiende un READY sin repartidor ni un ON_THE_WAY vencido; el admin no puede reasignar; repartidores «disponibles» que cerraron la app |
| Push | Ícono de notificación en blanco, sin avisos con la app abierta, sin ayuda para el ahorro de batería de Xiaomi/Huawei |
| Publicación | `versionCode` siempre 1 y el CI no arma App Bundle; sin actualización obligatoria; la web sin servicio en Railway; `CORS_ORIGINS` fuera de `railway.ts`; sin backups de Postgres |
| Paridad del panel | Agotar en un toque y acciones en lote, filtro «sin foto», ordenar secciones arrastrando, precio de antes en la revisión del import, no guardar mientras sube una foto, aviso al cerrar un formulario con cambios |

## 3. Después del piloto

| Pendiente | Detalle |
|---|---|
| iOS | Push sin configurar (falta `GoogleService-Info.plist` y la llave APNs) y la key de mapas. Solo si se publica en App Store |
| Reseñas | Los clientes califican, pero ni el admin ni el negocio las ven |
| Soporte | Botón de ayuda o WhatsApp dentro de la app (hoy solo en la landing) |
| Observabilidad | Logs JSON con `requestId`. Faltan Sentry y métricas |
| Escala | Rate limit y WebSocket en memoria: con varias instancias, Redis |
| Pagos en línea | Culqi o Mercado Pago (Fase 4). Hoy efectivo, Yape y Plin al recibir |
| Catálogo base para bodegas | Productos de marca comunes (Inca Kola 500 ml, leche Gloria) con foto y presentación: la tienda marca los que vende y pone su precio, sin subir fotos. Ojo con la licencia si se siembra desde Open Food Facts (CC-BY-SA) |
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
| 17 | Fotos reales (✅ subida a R2 e importación desde Excel o CSV; ✅ sesión web en cookie) | 1 día | Abrir el Portal Socios a negocios |
| 18 | ✅ Editor de variantes, mapa de repartidores, ubicación de fondo y sesión web en cookie | — | Operación sin parches |
| 19 | Carta desde una foto con IA | 2–3 días | Alta de un restaurante en minutos |
