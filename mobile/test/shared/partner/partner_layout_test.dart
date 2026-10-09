import 'dart:io';

import 'package:apamuy/features/courier_deliveries/courier_deliveries.dart';
import 'package:apamuy/features/merchant_orders/merchant_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

/// Capturas opcionales de las pantallas reales con el backend de demostración.
/// flutter test --update-goldens --dart-define=CAPTURE_PARTNER_UI=true test/shared/partner/partner_layout_test.dart
Future<void> _capture(Finder page, String name) async {
  if (const bool.fromEnvironment('CAPTURE_PARTNER_UI')) {
    await expectLater(page, matchesGoldenFile('../../../../docs/ui/partner/$name.png'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final cache = Directory.systemTemp.createTempSync('apamuy_partner_ui_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cache.path,
    );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      // Solo elimina el directorio temporal creado por esta prueba.
      if (cache.absolute.parent.path == Directory.systemTemp.absolute.path && cache.existsSync()) {
        await cache.delete(recursive: true);
      }
    });
    for (final (family, asset) in [
      ('Jakarta', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
      ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final (name, size, scale, brightness) in [
    ('móvil', const Size(390, 844), 1.0, Brightness.light),
    ('compacto con texto grande', const Size(320, 720), 1.4, Brightness.light),
    ('tablet oscuro', const Size(1024, 768), 1.0, Brightness.dark),
  ]) {
    testWidgets('tienda: pedidos y catálogo en $name', (tester) async {
      final container = await pumpPartner(
        tester,
        signedInAs: 'usr_owner_chaski_dorado',
        size: size,
        textScale: scale,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Tu negocio', findRichText: true), findsOneWidget);
      if (name == 'móvil') await _capture(find.byType(MerchantHomePage), 'tienda_pedidos');
      // Elegir el tiempo cambia el botón sin enviar el pedido al fogón.
      await tester.ensureVisible(find.text('30 min'));
      await settle(tester);
      await tester.tap(find.text('30 min'));
      await settle(tester);
      expect(find.text('Aceptar · listo en 30 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, 1000));
      await settle(tester);
      await tester.tap(find.byTooltip('Productos'));
      await settle(tester);
      expect(find.byType(MerchantProductsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (name == 'móvil') await _capture(find.byType(MerchantProductsPage), 'tienda_catalogo');
      await tester.enterText(find.byType(TextField), 'producto que no existe');
      await settle(tester);
      expect(find.text('Sin coincidencias'), findsOneWidget);
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await settle(tester);
      expect(find.text('Sin coincidencias'), findsNothing);
      await unmountApamuy(tester, container);
    });

    testWidgets('repartidor: disponibilidad, recorrido y cobro en $name', (tester) async {
      final container = await pumpPartner(
        tester,
        signedInAs: 'usr_courier_luis',
        size: size,
        textScale: scale,
        brightness: brightness,
      );
      expect(find.text('Desconectado'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(find.text('En ruta · conectado'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (name == 'móvil') await _capture(find.byType(CourierHomePage), 'repartidor_pedidos');
      await tester.ensureVisible(find.text('Tomar recorrido').first);
      await settle(tester);
      await tester.tap(find.text('Tomar recorrido').first);
      await settle(tester);
      expect(find.byType(ActiveDeliveryPage), findsOneWidget);
      expect(find.text('Recoge el pedido'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (name == 'móvil') await _capture(find.byType(ActiveDeliveryPage), 'repartidor_entrega');
      Navigator.of(tester.element(find.byType(ActiveDeliveryPage))).pop();
      await settle(tester);
      expect(find.text('Continuar entrega'), findsOneWidget);
      await tester.ensureVisible(find.text('Continuar entrega'));
      await settle(tester);
      await tester.tap(find.text('Continuar entrega'));
      await settle(tester);
      await tester.drag(find.text('Lo recogí'), const Offset(600, 0));
      await settle(tester);
      expect(find.text('Entrega y cobra'), findsOneWidget);
      await tester.drag(find.text('Entregado'), const Offset(600, 0));
      await settle(tester);
      expect(find.text('Medio de pago recibido'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // El formulario se puede desplazar incluso con el teclado abierto.
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(find.byType(TextField), 'no válido');
      await settle(tester);
      expect(find.text('Escribe un monto válido'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await unmountApamuy(tester, container);
    });
  }

  testWidgets('tablet: riel de comandas y resumen de ventas', (tester) async {
    final container = await pumpPartner(
      tester,
      signedInAs: 'usr_owner_chaski_dorado',
      size: const Size(1024, 768),
      brightness: Brightness.dark,
    );
    // Las tres barras a la vista: la comanda nueva cuelga a la izquierda del fogón.
    final fresh = find.text('Aceptar · listo en 20 min');
    final cooking = find.text('Listo para recoger');
    expect(fresh, findsOneWidget);
    expect(cooking, findsOneWidget);
    expect(tester.getCenter(fresh).dx, lessThan(tester.getCenter(cooking).dx));
    await tester.tap(fresh);
    await settle(tester);
    expect(find.text('Listo para recoger'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.drag(find.byType(NestedScrollView), const Offset(0, 1000));
    await settle(tester);
    await _capture(find.byType(MerchantHomePage), 'tienda_tablet_oscuro');
    await tester.tap(find.text('Hoy'));
    await settle(tester);
    expect(find.text('Vendido hoy'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApamuy(tester, container);
  });

  testWidgets('catálogo: buscar, agotar y recuperar el producto desde el filtro', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    await tester.tap(find.byTooltip('Productos'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Pollo entero');
    await tester.tap(find.textContaining('Disponibles ('));
    await settle(tester);
    await tester.ensureVisible(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(find.text('Sin coincidencias'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Agotados ('));
    await settle(tester);
    await tester.tap(find.textContaining('Agotados ('));
    await settle(tester);
    expect(find.text('Pollo entero a la brasa'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Sin coincidencias'), findsOneWidget);
    await unmountApamuy(tester, container);
  });
}
