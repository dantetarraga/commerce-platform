# Chaski — Operación con negocios y repartidores

Versión 0.1 · 2026-09-25 · Complementa [ARQUITECTURA.md](ARQUITECTURA.md) y [PENDIENTES.md](PENDIENTES.md).

Este documento define cómo se opera Chaski del lado de los socios: cómo recibe un pedido la tienda, cómo lo lleva el repartidor, cómo se cobra y cómo se da de alta a un socio.

## 1. Las piezas

Hay un solo backend y tres clientes, al estilo de Rappi o PedidosYa:

| Pieza | Quién la usa | Roles | Qué hace |
|---|---|---|---|
| **App Chaski** (`mobile/`, flavor `customer`) | Clientes | `CUSTOMER` | Pedir, pagar al recibir, seguir el pedido |
| **App Chaski Socios** (`mobile/`, flavor `partner`) | Negocios y repartidores | `MERCHANT`, `COURIER` | Modo Negocio o modo Repartidor según el rol |
| **Panel admin** (web, más adelante) | El equipo de Chaski | `ADMIN` | Alta de socios, pedidos en vivo, catálogo, soporte |

- **Una sola cuenta por celular.** Una persona con tienda que también pide comida usa el mismo número en las dos apps (`UserRole` admite varios roles).
- **Por qué dos apps y no una:** la alarma de pedidos necesita permisos especiales de Android que no corresponde pedirles a los clientes. Además, los socios reciben actualizaciones más seguido.
- **Negocio y repartidor comparten app** mientras haya pocos socios. Si crece, el modo Repartidor se separa en su propia app sin reescribir nada: todo sale del mismo proyecto Flutter.
- Mientras no exista el panel admin, el equipo opera desde Swagger (`/docs`).

## 2. Cómo recibe el pedido una tienda

```
Cliente pide ─► RECEIVED ─► 🔔 alarma en Chaski Socios (push + sonido en bucle)
                   │
                   ├─ Acepta con tiempo (10/20/30/45 min) ─► PREPARING (pasa por CONFIRMED)
                   ├─ Rechaza con motivo ─► CANCELLED, se avisa al cliente
                   └─ No responde:
                        · 3 min  → alerta al admin (lo llamamos)
                        · 8 min  → Chaski lo cancela y avisa al cliente
PREPARING ─► "Listo para recoger" (READY) ─► lo toma un repartidor
```

- **Aceptar** hace RECEIVED → CONFIRMED → PREPARING de una vez y recalcula la hora estimada. El cliente recibe un solo aviso.
- **Rechazar** exige un motivo ("Sin stock: Pollo a la brasa", "Cerrado", otro). Restaura el stock y el cupón.
- **Pedidos programados:** el plazo de aceptación empieza 60 min antes de la hora programada, no al crearlo.
- **Cancelación automática:** se registra sin rol (`cancelledBy = null`). El cliente ve "Cancelado por Chaski: el negocio no respondió a tiempo".
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
- **Pendiente de definir:** la comisión de Chaski, el costo de envío para el repartidor y las liquidaciones semanales a los negocios. Durante la prueba no se modelan.

## 5. Alta de socios

**Durante la prueba, el equipo da de alta a cada socio.** No hay registro abierto.

1. El negocio o repartidor se contacta con nosotros (WhatsApp o en persona).
2. Verificamos:
   - negocio: RUC o RUS, DNI del responsable, local;
   - repartidor: DNI, licencia, SOAT, vehículo.
3. El admin lo da de alta por su celular: `POST admin/merchants` o `POST admin/couriers`. Si el celular no tiene cuenta, se crea.
4. El socio instala Chaski Socios, entra con su celular y el código SMS, y ya ve su modo.

Si alguien sin rol de socio entra a Chaski Socios, ve "Aún no eres socio de Chaski" y un botón para escribirnos.

**Suspensión:** `POST admin/users/:id/suspend-partner` quita el rol y cierra sus sesiones. Un repartidor con un pedido activo no se puede suspender hasta resolver ese pedido. Las tiendas de un negocio suspendido dejan de recibir pedidos.

**Después:** registro desde la app con solicitud, documentos en un bucket privado y aprobación desde el panel admin. La tienda se crea en borrador (`DRAFT`) y se publica cuando su menú está listo.

## 6. Lo legal pendiente

Antes de abrir al público:
- términos y condiciones y política de privacidad (Ley 29733, con la inscripción del banco de datos personales);
- Libro de Reclamaciones virtual (Indecopi);
- contrato de afiliación para negocios y términos para repartidores;
- guardar qué versión de los términos aceptó cada usuario y cuándo.

Los textos los tiene que revisar un abogado.
