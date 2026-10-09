# Mobile (Flutter: app del cliente y Apamuy Socios)

## Convenciones (prevalecen sobre las skills del plugin `dart-flutter`)

- **Por feature con DDD**: `features/<feature>/{domain,infrastructure,presentation}` y un barrel `<feature>.dart`. No reorganizar en capas globales, aunque `flutter-apply-architecture-best-practices` lo proponga.
- **Entre features solo se importan barrels** de la raíz del feature. El `domain/` de otro feature importa `<feature>_domain.dart` (solo Dart puro); hay entradas extra por consumidor (`orders_customer`, `orders_staff`, `orders_infrastructure`). Se usan providers públicos, nunca el repositorio de otro feature.
- **Sin ciclos entre features**: si dos pantallas se necesitan, las conecta el router de `apps/` con un widget o un callback (p. ej. `FavoriteToggle` en el detalle de un negocio). `test/architecture/architecture_test.dart` verifica estas reglas.
- `domain/` es Dart puro: sin Flutter, Dio ni anotaciones de JSON. Value objects en `core/domain` (`Money`, `PhoneNumber`, `GeoCoordinates`…).
- **Red con Dio** a través de `core/network/api_client.dart` (convierte errores a `AppException`). No usar el paquete `http` (`flutter-use-http-package` no aplica).
- **Repositorios devuelven `Result<T>`** usando `guard()`; la UI nunca ve excepciones ni Dio.
- **DTOs con `json_serializable`** en `infrastructure/models` y mappers explícitos a entidades.
- **Cada datasource tiene su versión `Api*` y `Fake*`** con el mismo JSON; `USE_FAKE_DATA` elige cuál (`env/fake.json`, `env/dev.json`). Si cambias el contrato, cambia ambos y el backend.
- **Riverpod** (`riverpod_generator`) y **go_router** con `static const name` por página.
- **Tests con `mocktail`**, no mockito (`dart-generate-test-mocks` no aplica). Helpers en `test/helpers/`.
- Textos de UI en español.
- Paquete Dart `apamuy` (`package:apamuy/...`); raíces `ApamuyApp` y `PartnerApp`. Las claves `chaski.*` solo se conservan para migrar almacenamiento antiguo y en sus pruebas.
- Términos y privacidad en `assets/legal/*.md` (Markdown); los muestra `shared/legal/legal_page.dart` en las dos apps, y un enlace `apamuy:<slug>` abre el otro texto.

## Dos apps, un proyecto

- **Cliente**: `lib/main.dart` + `lib/apps/customer/`, flavor Android `customer` (`pe.apamuy.app`).
- **Apamuy Socios** (negocio y repartidor): `lib/main_partner.dart` + `lib/apps/partner/`, flavor `partner` (`pe.apamuy.socios`). Features propias: `partner_session`, `merchant_orders`, `courier_deliveries`.
- `apps/` solo compone: raíz, router y shell de cada app (la barra de compra conectada vive en `apps/customer/shell/`). Features, `core` y `shared` no la importan.
- Comparten `core/`, `shared/`, `auth` y el dominio de `orders`. **La app del cliente no importa features de socios ni al revés.**
- En Android el flavor es obligatorio. iOS solo tiene la app del cliente (se corre sin `--flavor`).

## Comandos

```bash
# Cliente
flutter run --flavor customer --dart-define-from-file=env/fake.json   # demo sin backend
flutter run --flavor customer --dart-define-from-file=env/dev.json    # contra la API local (emulador Android)
flutter run --flavor customer --dart-define-from-file=env/dev-device.json  # teléfono (con `adb reverse tcp:3000 tcp:3000`)
flutter run --dart-define-from-file=env/dev-device.json               # simulador iOS (sin flavor)
# Apamuy Socios (mismos env; demo: negocio 910000000, repartidor 900000101, código 123456)
flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/fake.json
flutter build apk --flavor partner -t lib/main_partner.dart          # APK para pasar a los socios
dart run build_runner build --delete-conflicting-outputs
# Marca (PNG en assets/brand, generados desde la "a" de BrandMarkPainter)
dart run flutter_launcher_icons                                     # íconos Android por flavor
dart run flutter_native_splash:create --flavor customer             # arranque nativo (y --flavor partner)
dart run flutter_launcher_icons -f tool/brand/ios_icons.yaml        # iOS (sin flavor): mover antes los flutter_launcher_icons-*.yaml
dart run flutter_native_splash:create --path=tool/brand/ios_splash.yaml
flutter analyze && flutter test
```
