import 'dart:io';

import 'package:chaski/features/courier_deliveries/courier_deliveries.dart';
import 'package:chaski/features/home/presentation/pages/home_page.dart';
import 'package:chaski/features/merchant_orders/merchant_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/design_capture.dart';

Future<void> _capture(WidgetTester tester, Finder page, String name) async {
  if (!name.startsWith('cliente_')) await captureCity(tester, 'socios_$name');
  if (!const bool.fromEnvironment('CAPTURE_UI_REFRESH')) return;
  // Permite que flutter_svg termine de decodificar los assets locales.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await settle(tester);
  await expectLater(page, matchesGoldenFile('../../../docs/ui/refresh/$name.png'));
}

void main() {
  setUpAll(() async {
    final cache = Directory.systemTemp.createTempSync('chaski_ui_refresh_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cache.path,
    );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      if (cache.absolute.parent.path == Directory.systemTemp.absolute.path && cache.existsSync()) {
        await cache.delete(recursive: true);
      }
    });
    for (final (family, asset) in [
      ('Jakarta', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
      ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final (name, size, scale, brightness) in [
    ('movil', const Size(390, 844), 1.0, Brightness.light),
    ('compacto', const Size(320, 720), 1.4, Brightness.light),
    ('oscuro', const Size(390, 844), 1.0, Brightness.dark),
  ]) {
    testWidgets('inicio del cliente y cuenta de socios en $name', (tester) async {
      final customer = await pumpChaski(tester, signedIn: true, size: size, textScale: scale, brightness: brightness);
      expect(find.text('¿Qué te provoca hoy?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (name != 'compacto') await _capture(tester, find.byType(HomePage), 'cliente_$name');
      await unmountChaski(tester, customer);

      final partner = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado', size: size, textScale: scale, brightness: brightness);
      if (name != 'compacto') await _capture(tester, find.byType(MerchantHomePage), 'negocio_$name');
      await tester.tap(find.byTooltip('Tu cuenta'));
      await settle(tester);
      expect(find.text('Negocio'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmountChaski(tester, partner);
      // flutter_cache_manager programa la limpieza de su caché a los 10 s.
      await tester.pump(const Duration(seconds: 12));
    });
  }

  testWidgets('repartidor cambia su disponibilidad sin perder el contexto', (tester) async {
    final partner = await pumpPartner(tester, signedInAs: 'usr_courier_luis');
    expect(find.text('Desconectado'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('En ruta · conectado'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, find.byType(CourierHomePage), 'repartidor_movil');
    await unmountChaski(tester, partner);
    await tester.pump(const Duration(seconds: 12));
  });
}
