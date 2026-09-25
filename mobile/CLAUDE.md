# Mobile (Flutter, app del cliente)

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

## Comandos

```bash
flutter run --dart-define-from-file=env/fake.json   # demo sin backend
flutter run --dart-define-from-file=env/dev.json    # contra la API local (emulador Android)
flutter run --dart-define-from-file=env/dev-device.json  # teléfono (con `adb reverse tcp:3000 tcp:3000`) o simulador iOS
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```
