import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/app/config/env.dart';
import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/core/storage/preferences_storage.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/core/storage/token_storage.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Preferencias en memoria (onboarding visto o no).
class MemoryPreferences implements PreferencesStorage {
  MemoryPreferences({this.onboardingSeen = true});

  bool onboardingSeen;

  @override
  Future<bool> isOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> markOnboardingSeen() async => onboardingSeen = true;
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      preferencesStorageProvider.overrideWithValue(MemoryPreferences(onboardingSeen: onboardingSeen)),
      tokenStorageProvider.overrideWithValue(
        MemoryTokens(signedIn ? (accessToken: 'fake-access.usr_demo_customer', refreshToken: 'fake-refresh.x') : null),
      ),
      localJsonStoreProvider.overrideWithValue(MemoryJsonStore()),
      fakeBackendProvider.overrideWithValue(FakeBackend(latency: const Duration(milliseconds: 10), orderStep: orderStep)),
      appEnvProvider.overrideWithValue(const AppEnv(apiBaseUrl: 'http://test', useFakeData: true)),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: container.read(appRouterProvider),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
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
Future<void> unmountChaski(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
}

/// `pumpAndSettle` no sirve con shimmer y animaciones en bucle: avanza el
/// reloj un tiempo fijo.
Future<void> settle(WidgetTester tester, {int frames = 20, Duration step = const Duration(milliseconds: 50)}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

String currentPath(ProviderContainer c) => c.read(appRouterProvider).routeInformationProvider.value.uri.path;
