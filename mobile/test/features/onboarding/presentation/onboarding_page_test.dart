import 'dart:async';

import 'package:apamuy/app/router/app_router.dart';
import 'package:apamuy/app/router/routes.dart';
import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/config/env.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/core/storage/preferences_storage.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';
import 'package:apamuy/features/auth/presentation/providers/auth_providers.dart';
import 'package:apamuy/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:apamuy/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Preferences extends Mock implements PreferencesStorage {}

class _Auth extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Fuentes reales para que las pruebas de desborde midan texto de verdad.
    final jakarta = FontLoader('Jakarta')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    final outfit = FontLoader('Outfit')..addFont(rootBundle.load('assets/fonts/Outfit-Variable.ttf'));
    await Future.wait([jakarta.load(), outfit.load()]);
  });
  late _Preferences preferences;
  late _Auth auth;

  setUp(() {
    preferences = _Preferences();
    auth = _Auth();
    when(preferences.isOnboardingSeen).thenAnswer((_) async => false);
    when(preferences.markOnboardingSeen).thenAnswer((_) async {});
    when(auth.restoreSession).thenAnswer((_) async => const Result.ok(null));
  });

  Future<ProviderContainer> pumpOnboarding(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        preferencesStorageProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(auth),
        localJsonStoreProvider.overrideWithValue(MemoryJsonStore()),
        appEnvProvider.overrideWithValue(const AppEnv(apiBaseUrl: 'http://test', useFakeData: false)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: theme ?? AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reducedMotion),
            child: child!,
          ),
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  int step(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller!.page!.round() + 1;

  String path(ProviderContainer c) => c.read(appRouterProvider).routeInformationProvider.value.uri.path;

  Future<void> tapVisible(WidgetTester tester, String label) async {
    final finder = find.text(label).hitTestable();
    if (finder.evaluate().isEmpty) {
      await tester.ensureVisible(find.text(label).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(label).hitTestable().first);
    await tester.pumpAndSettle();
  }

  testWidgets('recorre la historia y abre la entrada con celular', (tester) async {
    final container = await pumpOnboarding(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text(onboardingSlides[0].title), findsOneWidget);
    await tapVisible(tester, 'Siguiente');
    expect(step(tester), 2);
    await tapVisible(tester, 'Siguiente');
    expect(step(tester), 3);
    expect(find.text('Saltar'), findsNothing);
    await tapVisible(tester, 'Empezar a pedir');
    expect(path(container), RoutePaths.login);
    verify(preferences.markOnboardingSeen).called(1);
  });

  testWidgets('saltar lleva directamente a la entrada', (tester) async {
    final container = await pumpOnboarding(tester);
    await tapVisible(tester, 'Saltar');
    expect(path(container), RoutePaths.login);
    verify(preferences.markOnboardingSeen).called(1);
  });

  testWidgets('un onboarding ya visto no vuelve a interrumpir el inicio', (tester) async {
    when(preferences.isOnboardingSeen).thenAnswer((_) async => true);
    final container = await pumpOnboarding(tester);
    expect(path(container), RoutePaths.login);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('swipe, indicador y retroceso mantienen el paso correcto', (tester) async {
    await pumpOnboarding(tester);
    await tester.drag(find.byType(PageView), const Offset(-330, 0));
    await tester.pumpAndSettle();
    expect(step(tester), 2);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(step(tester), 1);
    await tester.tap(find.bySemanticsLabel('Ir al paso 3'));
    await tester.pumpAndSettle();
    expect(step(tester), 3);
  });

  testWidgets('bloquea envíos duplicados mientras guarda', (tester) async {
    final pending = Completer<void>();
    when(preferences.markOnboardingSeen).thenAnswer((_) => pending.future);
    final container = await pumpOnboarding(tester);
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(find.byType(AppLoader), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    verify(preferences.markOnboardingSeen).called(1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(path(container), RoutePaths.login);
  });

  testWidgets('si falla el guardado permite reintentar sin abandonar la historia', (tester) async {
    when(preferences.markOnboardingSeen).thenAnswer((_) async => throw Exception('storage unavailable'));
    final container = await pumpOnboarding(tester);
    // Sin pumpAndSettle: el aviso tiene una barra de tiempo y se iría antes de verlo.
    await tester.tap(find.text('Saltar').hitTestable().first);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No pudimos guardar tu avance. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsOneWidget);
    AppToast.dismiss();
    when(preferences.markOnboardingSeen).thenAnswer((_) async {});
    await tapVisible(tester, 'Saltar');
    expect(path(container), RoutePaths.login);
  });

  for (final configuration in [
    (name: 'pantalla pequeña', size: const Size(320, 568), scale: 1.0, dark: false),
    (name: 'texto al 200%', size: const Size(320, 568), scale: 2.0, dark: false),
    (name: 'horizontal', size: const Size(844, 390), scale: 1.0, dark: false),
    (name: 'modo oscuro', size: const Size(390, 844), scale: 1.0, dark: true),
  ]) {
    testWidgets('acciones alcanzables y sin desbordes: ${configuration.name}', (tester) async {
      final container = await pumpOnboarding(
        tester,
        size: configuration.size,
        textScale: configuration.scale,
        theme: configuration.dark ? AppTheme.dark() : AppTheme.light(),
      );
      for (final slide in onboardingSlides) {
        await tapVisible(tester, slide.cta);
        expect(tester.takeException(), isNull, reason: slide.cta);
      }
      expect(path(container), RoutePaths.login);
    });
  }

  testWidgets('movimiento reducido avanza sin una transición animada', (tester) async {
    await pumpOnboarding(tester, reducedMotion: true);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(step(tester), 2);
    final controller = tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(controller.page, 1);
    expect(controller.position.isScrollingNotifier.value, isFalse);
    final router = GoRouter.of(tester.element(find.byType(OnboardingPage)));
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.onboarding);
  });
}
