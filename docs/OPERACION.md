# Apamuy — Operación con negocios y repartidores

Versión 0.1 · 2026-09-25 · Complementa [ARQUITECTURA.md](ARQUITECTURA.md) y [PENDIENTES.md](PENDIENTES.md).

Este documento define cómo se opera Apamuy del lado de los socios: cómo recibe un pedido la tienda, cómo lo lleva el repartidor, cómo se cobra y cómo se da de alta a un socio.

## 1. Las piezas

Hay un solo backend y tres clientes, al estilo de Rappi o PedidosYa:

| Pieza | Quién la usa | Roles | Qué hace |
|---|---|---|---|
| **App Apamuy** (`mobile/`, flavor `customer`) | Clientes | `CUSTOMER` | Pedir, pagar al recibir, seguir el pedido |
| **App Apamuy Socios** (`mobile/`, flavor `partner`) | Negocios y repartidores | `MERCHANT`, `COURIER` | Modo Negocio o modo Repartidor según el rol |
| **Panel admin** (web, más adelante) | El equipo de Apamuy | `ADMIN` | Alta de socios, pedidos en vivo, catálogo, soporte |

- **Una sola cuenta por celular.** Una persona con tienda que también pide comida usa el mismo número en las dos apps (`UserRole` admite varios roles).
- **Por qué dos apps y no una:** la alarma de pedidos necesita permisos especiales de Android que no corresponde pedirles a los clientes. Además, los socios reciben actualizaciones más seguido.
- **Negocio y repartidor comparten app** mientras haya pocos socios. Si crece, el modo Repartidor se separa en su propia app sin reescribir nada: todo sale del mismo proyecto Flutter.
- Mientras no exista el panel admin, el equipo opera desde Swagger (`/docs`).

## 2. Cómo recibe el pedido una tienda

```
Cliente pide ─► RECEIVED ─► 🔔 alarma en Apamuy Socios (push + sonido en bucle)
                   │
                   ├─ Acepta con tiempo (10/20/30/45 min) ─► PREPARING (pasa por CONFIRMED)
                   ├─ Rechaza con motivo ─► CANCELLED, se avisa al cliente
                   └─ No responde:
                        · 3 min  → alerta al admin (lo llamamos)
                        · 8 min  → Apamuy lo cancela y avisa al cliente
PREPARING ─► "Listo para recoger" (READY) ─► lo toma un repartidor
```

- **Aceptar** hace RECEIVED → CONFIRMED → PREPARING de una vez y recalcula la hora estimada. El cliente recibe un solo aviso.
- **Rechazar** exige un motivo ("Sin stock: Pollo a la brasa", "Cerrado", otro). Restaura el stock y el cupón.
- **Pedidos programados:** el plazo de aceptación empieza 60 min antes de la hora programada, no al crearlo.
- **Cancelación automática:** se registra sin rol (`cancelledBy = null`). El cliente ve "Cancelado por Apamuy: el negocio no respondió a tiempo".
- **Pausa:** el negocio puede dejar de recibir pedidos con un interruptor. Mientras está pausado, la app del cliente lo muestra cerrado.
- **Productos agotados:** el negocio los marca como no disponibles desde su app.

## 3. Cómo lleva el pedido el repartidor

1. **Se conecta** (`AVAILABLE`). Solo los repartidores conectados ven los pedidos listos de su ciudad y reciben el aviso.
2. **Toma un pedido.** Si dos lo intentan a la vez, gana uno y el otro ve "Otro repartidor lo tomó". Mientras tiene un pedido activo está `BUSY`: no puede tomar otro ni desconectarse.
3. **Recoge:** ve el negocio, su dirección, un botón para llamar y otro para abrir el mapa. Marca "Lo recogí" (`ON_THE_WAY`).
4. **Entrega:** ve la dirección y la referencia del cliente, cuánto cobrar y el vuelto. Marca "Entregado" indicando cómo pagó el cliente y cuánto recibió.
5. Al entregar, vuelve a estar `AVAILABLE`.

Hoy los pedidos se muestran a los repartidores recién en `READY`. Mostrarlos desde `CONFIRMED`, para que lleguen mientras cocinan, queda para después porque cambia la máquina de estados.

## 4. Cobro contraentrega

- **Medios aceptados:** efectivo, Yape y Plin, siempre al recibir. Tarjeta queda deshabilitada: los repartidores no tienen POS y no hay pasarela.
- **Quién cobra:** el repartidor, el total del pedido.
- **Registro:** al marcar "Entregado", el repartidor indica el método y el monto recibido. Queda guardado en el pago (`collectedById`, `collectedMethod`, `collectedAmount`, `collectedAt`). Si el monto no coincide con el total, se permite pero queda registrado.
- **Rendición:** el repartidor y el negocio ven un resumen del día (entregas, total, efectivo frente a Yape o Plin).
- **Pendiente de definir:** la comisión de Apamuy, el costo de envío para el repartidor y las liquidaciones semanales a los negocios. Durante la prueba no se modelan.

## 5. Alta de socios

**Durante la prueba, el equipo da de alta a cada socio.** No hay registro abierto.

1. El negocio o repartidor se contacta con nosotros (WhatsApp o en persona).
2. Verificamos:
   - negocio: RUC o RUS, DNI del responsable, local;
   - repartidor: DNI, licencia, SOAT, vehículo.
3. El admin lo da de alta por su celular desde Swagger (`/docs`, sesión con rol `ADMIN`). Si el celular no tiene cuenta, se crea como cliente y se le suma el rol; repetir el alta no duplica nada.
   - `POST admin/merchants` `{ phone, firstName, lastName, storeIds? }`: `storeIds` pasa esos negocios a su nombre (mientras no haya CRUD de catálogo, los negocios salen del seed).
   - `POST admin/couriers` `{ phone, firstName, lastName, cityId, vehicleType: MOTO|BICI|AUTO, vehicleLabel, plate?, activeSince? }`: volver a llamarlo actualiza el vehículo.
   - `GET admin/users?phone=` muestra la cuenta con sus roles, negocios y vehículo (sirve para obtener el `id`).
4. El socio instala Apamuy Socios, entra con su celular y el código SMS, y ya ve su modo.

Si alguien sin rol de socio entra a Apamuy Socios, ve "Aún no eres socio de Apamuy" y un botón para escribirnos.

**Suspensión:** `POST admin/users/:id/suspend-partner` `{ roles? }` quita los roles de socio (sin `roles`, los dos) y cierra sus sesiones; el access token que ya tenía sigue valiendo hasta que vence (15 min). Un repartidor con un pedido activo no se puede suspender hasta resolver ese pedido. Las tiendas de un negocio suspendido dejan de recibir pedidos.

**Cargar un negocio nuevo** (Swagger, sesión `ADMIN`; precios en céntimos como `{ amount, currency }`):

1. `POST admin/merchants` con el celular del dueño → su `id`.
2. `POST admin/stores` `{ cityId, ownerId, name, addressLine, latitude, longitude, categoryIds?, schedules?, … }`. Queda **en borrador** (`isActive: false`): la app del cliente no lo muestra.
3. `POST admin/stores/:id/sections` por cada sección de la carta y `POST admin/stores/:id/products` por cada producto, con `variants` (cada una con su precio) y `options` (grupos con `minSelect`/`maxSelect` y sus valores).
4. Revisar con `GET admin/stores/:id` y publicar con `PATCH admin/stores/:id` `{ isActive: true }`.

Para editar: `PATCH admin/products/:id` reemplaza `variants` y `options` si vienen; los elementos que traen `id` se editan y conservan su id (las bolsas guardadas en los teléfonos siguen valiendo), los nuevos van sin `id` y los que faltan se borran. El horario se reemplaza entero con `PUT admin/stores/:id/schedules` y se rechazan turnos que se pisan. Quitar un producto o un negocio (`DELETE`) lo oculta sin tocar los pedidos pasados; un negocio con pedidos en curso no se puede quitar. Las categorías se crean con `POST admin/categories`.

**Cupones y banners del inicio:**
- `POST admin/coupons` `{ code, label, type, percentOff | amountOff, maxDiscount?, minOrderAmount?, cityId?, storeId?, startsAt, endsAt, usageLimit?, perUserLimit?, firstOrderOnly? }`. El código se guarda en mayúsculas y no se cambia. `percentOff` es para `PERCENTAGE` (con `maxDiscount` como tope), `amountOff` para `FIXED_AMOUNT`, y `FREE_DELIVERY` no lleva monto. Para darlo de baja: `PATCH admin/coupons/:id` `{ isActive: false }`; no se borra porque hay pedidos que lo usaron.
- `POST admin/promotions` `{ cityId, title, subtitle?, imageUrl, startsAt, endsAt, storeId?, couponId?, sortOrder? }`: el banner sale en el inicio mientras esté vigente; al tocarlo abre el negocio y muestra el cupón si siguen activos. `DELETE admin/promotions/:id` lo quita.

**Después:** registro desde la app con solicitud, documentos en un bucket privado y aprobación desde el panel admin.

## 6. Lo legal pendiente

Antes de abrir al público:
- términos y condiciones y política de privacidad (Ley 29733, con la inscripción del banco de datos personales);
- Libro de Reclamaciones virtual (Indecopi);
- contrato de afiliación para negocios y términos para repartidores;
- guardar qué versión de los términos aceptó cada usuario y cuándo.

Los textos los tiene que revisar un abogado.

## 7. Contrato de la API para Apamuy Socios

Prefijo `/api/v1`. Montos como `{ amount, currency }` en céntimos. Fechas ISO-8601 UTC; `date=YYYY-MM-DD` es el día en hora de Lima (por defecto, hoy). Los datasources `Api*`/`Fake*` de `merchant_orders` y `courier_deliveries` en la app son la fuente de verdad de este contrato.

### Pedido para socios (`StaffOrder`)

Es el pedido del cliente (`OrderJson`) más:

| Campo | Tipo | Nota |
|---|---|---|
| `lines[].notes` | string | Nota del cliente para ese producto (`''` si no hay) |
| `customer` | `{ name, phone }` | |
| `deliveryLocation` | `{ lat, lng }` | |
| `pickup` | `{ address, phone, location: { lat, lng } }` | Dónde recoger: datos actuales del negocio (`phone` puede ser null) |
| `distanceMeters` | int | Del negocio al cliente |
| `cancelReason` | string \| null | |
| `collection` | `{ method, amount, collectedAt }` \| null | Lo que cobró el repartidor al entregar |

### Negocio (`MERCHANT`; el `ADMIN` ve todos)

| Método | Ruta | Cuerpo / query | Respuesta |
|---|---|---|---|
| GET | `merchant/stores` | | `[{ id, name, logoUrl, isAcceptingOrders, isOpenNow }]` |
| PATCH | `merchant/stores/:id` | `{ isAcceptingOrders }` | `{ id, name, isAcceptingOrders }` |
| GET | `merchant/orders` | `scope=active\|today`, `status?`, `cursor?`, `limit?` | `{ items: StaffOrder[], nextCursor }` |
| GET | `merchant/orders/:id` | | `StaffOrder` |
| POST | `merchant/orders/:id/accept` | `{ prepMinutes }` (5–90) | `StaffOrder` (queda en `PREPARING`) |
| POST | `merchant/orders/:id/status` | `{ status: "READY" }` | `StaffOrder` |
| POST | `merchant/orders/:id/cancel` | `{ reason }` (3–300) | `StaffOrder` |
| GET | `merchant/stores/:id/products` | | `[{ id, name, imageUrl, price, section, isAvailable }]` |
| PATCH | `merchant/products/:id` | `{ isAvailable }` | `{ id, isAvailable }` |
| GET | `merchant/summary` | `date?` | `{ date, deliveredCount, cancelledCount, activeCount, sales }` |

- `scope=active`: pedidos no finales (`RECEIVED` … `ON_THE_WAY`). `scope=today`: todos los creados ese día. Sin `scope`, todos.
- `sales` suma el `subtotal` de los entregados (lo que es del negocio; el envío es del repartidor).

### Repartidor (`COURIER`)

| Método | Ruta | Cuerpo / query | Respuesta |
|---|---|---|---|
| GET | `courier/me` | | `Courier` = `{ id, name, phone, vehicleLabel, status, activeOrderId }` |
| PATCH | `courier/me/status` | `{ status: "AVAILABLE" \| "OFFLINE" }` | `Courier` |
| GET | `courier/orders/available` | `cursor?`, `limit?` | `{ items: StaffOrder[], nextCursor }` (vacío si no está `AVAILABLE`) |
| GET | `courier/orders` | `scope=active\|today`, `cursor?`, `limit?` | `{ items: StaffOrder[], nextCursor }` |
| POST | `courier/orders/:id/accept` | | `StaffOrder` (el repartidor pasa a `BUSY`) |
| POST | `courier/orders/:id/status` | `{ status: "ON_THE_WAY" }` o `{ status: "DELIVERED", collectedMethod: "CASH"\|"YAPE"\|"PLIN", collectedAmount: Money }` | `StaffOrder` |
| GET | `courier/me/summary` | `date?` | `{ date, deliveredCount, collected: { total, CASH, YAPE, PLIN } }` |

- `status` del repartidor: `OFFLINE`, `AVAILABLE` o `BUSY`. Con un pedido activo está `BUSY`; al entregar o si se cancela su pedido vuelve a `AVAILABLE`.

### Errores nuevos

| Código | HTTP | Cuándo |
|---|---|---|
| `COURIER_HAS_ACTIVE_ORDER` | 409 | Desconectarse con un pedido en curso |
| `COURIER_NOT_AVAILABLE` | 409 | Tomar un pedido sin estar conectado o teniendo otro activo |
| `COLLECTION_REQUIRED` | 422 | Marcar entregado sin decir cómo pagó el cliente |
| `PAYMENT_METHOD_UNAVAILABLE` | 422 | Pedir con tarjeta (solo contraentrega: efectivo, Yape o Plin) |
