import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/design_capture.dart';

/// Capturas opcionales de la animación de arranque:
/// flutter test --update-goldens --dart-define=CAPTURE_SPLASH=true test/features/auth/splash_animation_test.dart
Future<void> _shot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_SPLASH')) return;
  await expectLater(find.byType(Overlay).first, matchesGoldenFile('../../../../../docs/ui/arranque/$name.png'));
}

void main() {
  setUpAll(loadDesignFonts);

  testWidgets('el arranque muestra la entrada completa y luego entra al inicio', (tester) async {
    final container = await pumpApamuy(tester, signedIn: true, playSplash: true, latency: const Duration(milliseconds: 50));
    // _pumpApp ya avanzó 1 s: seguimos en la entrada.
    expect(find.byType(SplashPage), findsOneWidget);
    expect(container.read(splashGateProvider), isFalse);
    await _shot(tester, 'entrada');
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'palabra');
    // Termina la entrada y la salida (el pedido se abre).
    await tester.pump(const Duration(milliseconds: 300));
    await _shot(tester, 'salida');
    await settle(tester, frames: 30);
    expect(container.read(splashGateProvider), isTrue);
    expect(find.byType(HomePage), findsOneWidget);
    await unmountApamuy(tester, container);
  });

  testWidgets('si la sesión tarda, el arranque espera con el relevo del pedido', (tester) async {
    final container = await pumpApamuy(tester, signedIn: true, playSplash: true, latency: const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SplashPage), findsOneWidget);
    expect(container.read(splashGateProvider), isFalse);
    await tester.pump(const Duration(milliseconds: 700));
    await _shot(tester, 'espera');
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, frames: 30);
    expect(container.read(splashGateProvider), isTrue);
    expect(find.byType(HomePage), findsOneWidget);
    await unmountApamuy(tester, container);
    // Deja terminar las consultas lentas del backend de prueba.
    await tester.pump(const Duration(seconds: 5));
  });
}
