# Apamuy · Flutter

Un solo proyecto con dos apps que comparten componentes, tokens y datos:

| App | Para quién | Flavor Android | Punto de entrada |
|---|---|---|---|
| **Apamuy** | Cliente | `customer` (`pe.apamuy.app`) | `lib/main.dart` |
| **Apamuy Socios** | Negocio (tienda) y repartidor | `partner` (`pe.apamuy.socios`) | `lib/main_partner.dart` |

En Socios, el **modo** (Negocio o Repartidor) lo decide la cuenta con la que entras: el dueño de un negocio ve sus pedidos y el repartidor, sus entregas. Si una cuenta tiene los dos roles, elige el modo al entrar.

## Identidad y datos guardados

El paquete Dart es `apamuy` y los imports internos usan `package:apamuy/...`. Las raíces son `ApamuyApp` y `PartnerApp`; Android usa el namespace `pe.apamuy`. Los identificadores instalables siguen siendo `pe.apamuy.app` y `pe.apamuy.socios`.

Al actualizar una instalación con esos mismos identificadores, el almacenamiento migra las claves antiguas `chaski.*` a `apamuy.*` cuando se leen. Conserva sesión, bolsa, direcciones, favoritos, búsquedas, checkout, tema, onboarding y modo de Socios. Los valores nuevos tienen prioridad; escribir o borrar también retira la clave antigua. Cerrar sesión limpia ambas versiones de los tokens. Esta compatibilidad y sus pruebas son referencias históricas intencionales a Chaski.

Los nombres e identificadores de la tienda demo «El Chaski Dorado» siguen siendo datos del catálogo compartido con el backend. La URL de origen de los avatares conserva la semilla con la que se generaron.

## Antes de empezar

```sh
cd mobile
flutter pub get
```

- **Mapa de Google (Android):** agrega tu key en `android/local.properties` (git lo ignora):
  ```properties
  MAPS_API_KEY=tu_key
  ```
  Sin ella la app funciona igual, pero el mapa sale en gris. En web, iOS y los tests se usa el plano dibujado.
- **Dispositivo:** `flutter devices` lista los conectados. Con varios, elige uno con `-d <id>`.
- En Android el `--flavor` es **obligatorio**.

## Entornos

Cada archivo de `env/` se pasa con `--dart-define-from-file`:

| Archivo | Backend | Para |
|---|---|---|
| `env/fake.json` | Ninguno: datos en memoria (modo demo) | Probar la app sin levantar nada |
| `env/dev.json` | `http://10.0.2.2:3000` | Emulador de Android contra el backend local |
| `env/dev-device.json` | `http://localhost:3000` | Celular por USB (con `adb reverse`) o simulador de iOS |

## 1. Sin backend (modo demo)

No hace falta Docker ni el backend. Los pedidos avanzan solos cada pocos segundos y, al ir en camino, una moto simulada va del negocio a tu puerta en el mapa.

```sh
# Cliente
flutter run --flavor customer --dart-define-from-file=env/fake.json

# Socios: tienda o repartidor (según la cuenta con la que entres)
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/fake.json
```

La pantalla de ingreso ofrece entrar con un toque. Cuentas del modo demo:

| Cuenta | Celular | Código |
|---|---|---|
| Cliente | `984123456` (o cualquier otro, que pide crear la cuenta) | `123456` |
| Tienda (Pollería El Chaski Dorado) | `910000000` | `123456` |
| Repartidor (Luis) | `900000101` | `123456` |

## 2. Con el backend local

Primero levanta el backend (detalles en [`backend/README.md`](../backend/README.md)):

```sh
docker compose up -d          # desde la raíz: Postgres en el puerto 5433
cd backend
npm run db:deploy && npm run db:seed   # la primera vez o tras una migración
npm run start:dev             # API en :3000 y WebSocket en /ws
```

En desarrollo no se envían SMS: el código es siempre **`123456`** (`OTP_DEV_CODE`) y también aparece en el log del backend.

### En el emulador de Android

```sh
# Cliente
flutter run --flavor customer --dart-define-from-file=env/dev.json

# Socios: tienda o repartidor
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev.json
```

### En un celular por USB

`adb reverse` hace que el celular vea el backend de tu PC como `localhost:3000` (API y WebSocket). Repítelo cada vez que conectes el cable.

```sh
adb reverse tcp:3000 tcp:3000

# Cliente
flutter run --flavor customer --dart-define-from-file=env/dev-device.json

# Socios: tienda o repartidor
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev-device.json
```

### En el simulador de iOS (solo cliente)

iOS no tiene flavors ni la app de Socios. El mapa sale dibujado hasta que haya key de iOS.

```sh
flutter run --dart-define-from-file=env/dev-device.json
```

### Cuentas del seed

| Cuenta | Celular | App |
|---|---|---|
| Cliente demo (Alex Quispe) | `984123456` | Apamuy |
| Tienda: Pollería El Chaski Dorado | `910000000` | Socios |
| Otras tiendas | `910000001` … `910000010` | Socios |
| Repartidores | `900000101` (Luis), `900000102` (Yeni) | Socios |
| Admin | `900000001` | Swagger (`http://localhost:3000/docs`) |

Cualquier otro celular entra a la app del cliente creando una cuenta nueva. El backend acepta **5 códigos por celular por hora**: si pruebas mucho con el mismo número, cambia de número o espera.

### Probar un pedido completo en vivo

1. **Cliente** (`984123456`): pide algo a la Pollería El Chaski Dorado y abre el seguimiento.
2. **Tienda** (`910000000`, en otro dispositivo): el pedido aparece al instante; acéptalo y márcalo listo.
3. **Repartidor** (`900000101`): conéctate, toma el pedido y márcalo en camino.
4. En la app del cliente, la moto se mueve en el mapa a medida que el repartidor camina con su celular.

Con un solo teléfono puedes usar el emulador para una app y el celular para la otra (cada uno con su archivo de `env/`).

## Compilar un APK

```sh
flutter build apk --flavor customer --dart-define-from-file=env/dev.json
flutter build apk --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev.json
```

Los APK quedan en `build/app/outputs/flutter-apk/`.

## Calidad

```sh
dart run build_runner build --delete-conflicting-outputs   # tras cambiar providers o DTOs
flutter analyze
flutter test
```

## Diseño

- [Concepto, diagnóstico y sistema visual](../docs/DIRECCION_VISUAL.md).
- [Pantallas y reproducción de capturas](../docs/ui/ciudad/README.md).
- [Fotografías de demostración y sustitución](assets/images/demo/README.md).
- [Asset Rive y preparación de las bibliotecas nativas para pruebas](assets/animations/README.md).

El seguimiento usa Google Maps en Android detrás de `DeliveryMapAdapter`; sin coordenadas o fuera de Android vuelve al recorrido ilustrado. Las fotografías provisionales corresponden al catálogo demo.
