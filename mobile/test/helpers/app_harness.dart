import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/app/config/env.dart';
import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/app_partner/router/partner_router.dart';
import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/core/storage/preferences_storage.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/core/storage/token_storage.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MemoryPreferences implements PreferencesStorage {
  MemoryPreferences({this.onboardingSeen = true});

  bool onboardingSeen;

  @override
  Future<bool> isOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> markOnboardingSeen() async => onboardingSeen = true;
}

/// Alarma de pedidos sin audio ni wakelock: registra lo que se pidió.
class RecordingAlarm implements OrderAlarm {
  bool ringing = false;
  int rings = 0;
  bool awake = false;

  @override
  Future<void> ring() async {
    if (!ringing) rings++;
    ringing = true;
  }

  @override
  Future<void> silence() async => ringing = false;

  @override
  Future<void> keepAwake({required bool on}) async => awake = on;
}

/// Tokens en memoria (sin plugin nativo).
class MemoryTokens implements TokenStorage {
  MemoryTokens([this._tokens]);

  StoredTokens? _tokens;

  @override
  Future<StoredTokens?> read() async => _tokens;

  @override
  Future<void> save(StoredTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

/// Monta la app completa con el backend fake (latencias cortas) y todo el
/// almacenamiento en memoria. Desmonta y libera el contenedor al terminar,
/// así no quedan temporizadores vivos.
Future<ProviderContainer> pumpChaski(
  WidgetTester tester, {
  bool onboardingSeen = true,
  bool signedIn = false,
  Size size = const Size(390, 844),
  Duration orderStep = const Duration(seconds: 2),
  bool disableAnimations = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Duration latency = const Duration(milliseconds: 10),
  bool playSplash = false,
}) => _pumpApp(
  tester,
  router: (c) => c.read(appRouterProvider),
  latency: latency,
  playSplash: playSplash,
  onboardingSeen: onboardingSeen,
  signedInAs: signedIn ? 'usr_demo_customer' : null,
  size: size,
  orderStep: orderStep,
  disableAnimations: disableAnimations,
  textScale: textScale,
  brightness: brightness,
);

/// Monta Apamuy Socios. [signedInAs] es el id de un usuario del fake de auth
/// (p. ej. `usr_owner_chaski_dorado` o `usr_courier_luis`).
Future<ProviderContainer> pumpPartner(
  WidgetTester tester, {
  String? signedInAs,
  OrderAlarm? alarm,
  Size size = const Size(390, 844),
  Duration orderStep = const Duration(seconds: 2),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Duration latency = const Duration(milliseconds: 10),
  bool playSplash = false,
}) => _pumpApp(
  tester,
  router: (c) => c.read(partnerRouterProvider),
  latency: latency,
  playSplash: playSplash,
  alarm: alarm,
  signedInAs: signedInAs,
  size: size,
  orderStep: orderStep,
  textScale: textScale,
  brightness: brightness,
);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required GoRouter Function(ProviderContainer) router,
  required Size size,
  required Duration orderStep,
  OrderAlarm? alarm,
  bool onboardingSeen = true,
  String? signedInAs,
  bool disableAnimations = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Duration latency = const Duration(milliseconds: 10),
  bool playSplash = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      preferencesStorageProvider.overrideWithValue(
        MemoryPreferences(onboardingSeen: onboardingSeen),
      ),
      tokenStorageProvider.overrideWithValue(
        MemoryTokens(
          signedInAs != null
              ? (
                  accessToken: 'fake-access.$signedInAs',
                  refreshToken: 'fake-refresh.x',
                )
              : null,
        ),
      ),
      localJsonStoreProvider.overrideWithValue(MemoryJsonStore()),
      fakeBackendProvider.overrideWithValue(
        FakeBackend(latency: latency, orderStep: orderStep),
      ),
      appEnvProvider.overrideWithValue(
        const AppEnv(apiBaseUrl: 'http://test', useFakeData: true),
      ),
      orderAlarmProvider.overrideWithValue(alarm ?? RecordingAlarm()),
      // La animación de arranque se prueba aparte; aquí no hace esperar a cada test.
      if (!playSplash) splashGateProvider.overrideWith(_OpenSplashGate.new),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        routerConfig: router(container),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(
                context,
              ).copyWith(
                disableAnimations: disableAnimations,
                textScaler: TextScaler.linear(textScale),
              ),
          child: child!,
        ),
      ),
    ),
  );
  addTearDown(container.dispose);
  await settle(tester);
  return container;
}

/// Desmonta la app y libera providers (cancela temporizadores periódicos).
/// Llamar al final de cada test que use [pumpChaski].
Future<void> unmountChaski(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  // Más que un aviso (AppToast dura 2.6 s), para que no quede su timer vivo.
  await tester.pump(const Duration(seconds: 3));
}

/// `pumpAndSettle` no sirve con shimmer y animaciones en bucle: avanza el
/// reloj un tiempo fijo.
Future<void> settle(
  WidgetTester tester, {
  int frames = 20,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

String currentPath(ProviderContainer c) =>
    c.read(appRouterProvider).routeInformationProvider.value.uri.path;

String currentPartnerPath(ProviderContainer c) =>
    c.read(partnerRouterProvider).routeInformationProvider.value.uri.path;

class _OpenSplashGate extends SplashGate {
  @override
  bool build() => true;
}
