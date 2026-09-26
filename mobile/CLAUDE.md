# Mobile (Flutter: app del cliente y Chaski Socios)

## Convenciones (prevalecen sobre las skills del plugin `dart-flutter`)

- **Por feature con DDD**: `features/<feature>/{domain,infrastructure,presentation}` y un barrel `<feature>.dart`. No reorganizar en capas globales, aunque `flutter-apply-architecture-best-practices` lo proponga.
- `domain/` es Dart puro: sin Flutter, Dio ni anotaciones de JSON. Value objects en `core/domain` (`Money`, `PhoneNumber`, `GeoCoordinates`…).
- **Red con Dio** a través de `core/network/api_client.dart` (convierte errores a `AppException`). No usar el paquete `http` (`flutter-use-http-package` no aplica).
- **Repositorios devuelven `Result<T>`** usando `guard()`; la UI nunca ve excepciones ni Dio.
- **DTOs con `json_serializable`** en `infrastructure/models` y mappers explícitos a entidades.
- **Cada datasource tiene su versión `Api*` y `Fake*`** con el mismo JSON; `USE_FAKE_DATA` elige cuál (`env/fake.json`, `env/dev.json`). Si cambias el contrato, cambia ambos y el backend.
- **Riverpod** (`riverpod_generator`) y **go_router** con `static const name` por página.
- **Tests con `mocktail`**, no mockito (`dart-generate-test-mocks` no aplica). Helpers en `test/helpers/`.
- Textos de UI en español.

## Dos apps, un proyecto

- **Cliente**: `lib/main.dart` + `lib/app/`, flavor Android `customer` (`pe.chaski.chaski`).
- **Chaski Socios** (negocio y repartidor): `lib/main_partner.dart` + `lib/app_partner/`, flavor `partner` (`pe.chaski.socios`). Features propias: `partner_session`, `merchant_orders`, `courier_deliveries`.
- Comparten `core/`, `shared/`, `auth` y el dominio de `orders`. **La app del cliente no importa features de socios ni al revés.**
- En Android el flavor es obligatorio. iOS solo tiene la app del cliente (se corre sin `--flavor`).

## Comandos

```bash
# Cliente
flutter run --flavor customer --dart-define-from-file=env/fake.json   # demo sin backend
flutter run --flavor customer --dart-define-from-file=env/dev.json    # contra la API local (emulador Android)
flutter run --flavor customer --dart-define-from-file=env/dev-device.json  # teléfono (con `adb reverse tcp:3000 tcp:3000`)
flutter run --dart-define-from-file=env/dev-device.json               # simulador iOS (sin flavor)
# Chaski Socios (mismos env; demo: negocio 910000000, repartidor 900000101, código 123456)
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/fake.json
flutter build apk --flavor partner -t lib/main_partner.dart          # APK para pasar a los socios
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```
