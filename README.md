# Apamuy

> Apamuy es "tráelo" en quechua. El nombre interno `chaski` solo queda en la carpeta raíz del proyecto.

> App de delivery multi-negocio (restaurantes, tiendas, farmacias) pensada para una ciudad pequeña y preparada para escalar a varias ciudades.

## Monorepo

```
chaski/
├── backend/     # API NestJS + Prisma + PostgreSQL
├── mobile/      # Flutter: app del cliente y Apamuy Socios (negocio y repartidor)
├── docs/        # Arquitectura, operación y pendientes
└── docker-compose.yml   # Postgres 16 para desarrollo (puerto 5433)
```

Del proyecto `mobile/` salen **dos apps** que se instalan por separado:

| App | Para quién | Entrada | Flavor Android |
|---|---|---|---|
| **Apamuy** | Clientes | `lib/main.dart` | `customer` (`pe.apamuy.app`) |
| **Apamuy Socios** | Negocios y repartidores | `lib/main_partner.dart` | `partner` (`pe.apamuy.socios`) |

## Cómo probarlo

### Opción A: modo demo (sin backend)

Con un emulador Android abierto o un teléfono conectado:

```bash
cd mobile
flutter pub get

# App del cliente
flutter run --flavor customer --dart-define-from-file=env/fake.json

# Apamuy Socios (negocio / repartidor)
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/fake.json
```

- **Cuentas demo** (el login las ofrece con un botón "Usar"), todas con el código **123456**:

  | Cuenta | Celular |
  |---|---|
  | Cliente | 984123456 |
  | Negocio | 910000000 |
  | Repartidor | 900000101 |

- **En Socios, como negocio:** entra un pedido nuevo cada ~40 s y suena la alarma.
- **En Socios, como repartidor:** lo que el negocio marca "listo" le aparece al repartidor. Para verlo, cierra sesión desde el avatar y entra con la otra cuenta.
- En demo las dos apps no se comunican: para eso está la opción B.

### Opción B: con el backend real (las dos apps conectadas)

**1. Backend**

```bash
docker compose up -d        # desde la raíz: Postgres en el puerto 5433
cd backend
npm install
npm run db:deploy           # migraciones
npm run db:seed             # Espinar, negocios y usuarios de prueba
npm run start:dev           # http://localhost:3000/api/v1 · Swagger en /docs
```

Más detalle en [backend/README.md](backend/README.md).

**2. Apps apuntando a la API**

```bash
cd mobile
# Emulador Android
flutter run --flavor customer --dart-define-from-file=env/dev.json
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev.json

# Teléfono real por USB: primero `adb reverse tcp:3000 tcp:3000` y usa env/dev-device.json
```

**3. Recorrer un pedido completo** (el código SMS en desarrollo es **123456**)

1. **Cliente** (984123456): pide en *Pollería El Chaski Dorado*, pagando con efectivo, Yape o Plin.
2. **Socios como negocio** (910000000): suena la alarma. Acepta con un tiempo y luego marca "listo".
3. **Socios como repartidor** (900000101): conéctate, toma el pedido, pulsa "Lo recogí" y luego "Entregado" registrando el cobro.
4. **Cliente:** el seguimiento muestra cada paso.

Para tener las dos apps a la vez, usa dos emuladores. La app del cliente también corre en Chrome, con `flutter run -d chrome --dart-define-from-file=env/fake.json` (en Chrome no se usa `--flavor`).

### Tests

```bash
cd backend && npm run lint && npm test && npm run test:e2e
cd mobile && flutter analyze && flutter test
```

## Documentación

- [Arquitectura y diseño inicial](docs/ARQUITECTURA.md)
- [Operación con negocios y repartidores](docs/OPERACION.md), con el contrato de la API de socios
- [Backend: arranque y endpoints](backend/README.md)
- [Mobile: convenciones y comandos](mobile/CLAUDE.md)
- [Qué falta para el MVP](docs/PENDIENTES.md)

## Estado

- **mobile**: flujo completo del cliente (solo contraentrega) y **Apamuy Socios**: el negocio acepta, rechaza, marca listo, pausa y agota productos; el repartidor toma, recoge y entrega registrando el cobro. Datos de demo (`env/fake.json`) o contra la API (`env/dev.json`).
- **backend**: auth por OTP, catálogo, pedidos, cupones, avisos, direcciones y la API de socios (`merchant/*`, `courier/*`).
- **Siguiente**: alta de socios por admin y push con plazo de aceptación. Ver [PENDIENTES](docs/PENDIENTES.md).
