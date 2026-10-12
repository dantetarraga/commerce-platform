import 'dart:async';
import 'dart:io';

import 'package:apamuy/apps/partner/router/partner_router.dart';
import 'package:apamuy/features/merchant_catalog/merchant_catalog.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/features/merchant_orders/merchant_orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

/// Capturas opcionales de la carta editable con el backend de demostración.
/// flutter test --update-goldens --dart-define=CAPTURE_PARTNER_UI=true test/features/merchant_catalog/menu_screens_test.dart
Future<void> _capture(Finder page, String name) async {
  if (const bool.fromEnvironment('CAPTURE_PARTNER_UI')) {
    await expectLater(page, matchesGoldenFile('../../../../docs/ui/partner/$name.png'));
  }
}

const _products = '/negocio/productos/st_chaski_dorado';

final Finder _soldOutTile = find.byWidgetPredicate((w) => w is Text && (w.data == 'agotado' || w.data == 'agotados'));

Future<void> _go(WidgetTester tester, ProviderContainer container, String location) async {
  container.read(partnerRouterProvider).go(location);
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final cache = Directory.systemTemp.createTempSync('apamuy_menu_ui_');
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
    ('móvil', const Size(390, 844), 1.0, Brightness.light),
    ('compacto con texto grande', const Size(320, 720), 1.4, Brightness.light),
    ('tablet oscuro', const Size(1024, 768), 1.0, Brightness.dark),
  ]) {
    testWidgets('carta editable en $name', (tester) async {
      final container = await pumpPartner(
        tester,
        signedInAs: 'usr_owner_chaski_dorado',
        size: size,
        textScale: scale,
        brightness: brightness,
      );
      final mobile = name == 'móvil';
      final tablet = size.width >= MerchantProductsPage.twoPaneWidth;

      await _go(tester, container, _products);
      expect(find.byType(MerchantProductsPage), findsOneWidget);
      expect(find.text('Nuevo producto'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (mobile) await _capture(find.byType(MerchantProductsPage), 'carta_lista');

      // Secciones e importar viven en el menú ⋯ de la cabecera.
      await tester.tap(find.byTooltip('Más opciones de la carta'));
      await settle(tester);
      expect(find.text('Importar Excel o CSV'), findsOneWidget);
      await tester.tap(find.text('Secciones'));
      await settle(tester);
      expect(find.byType(MenuSectionsPage), findsOneWidget);
      await _go(tester, container, _products);

      // Los conteos filtran; tocar el activo vuelve a todos.
      await tester.tap(_soldOutTile);
      await settle(tester);
      expect(find.text('Pollo entero a la brasa'), findsNothing);
      await tester.tap(_soldOutTile);
      await settle(tester);
      expect(tester.takeException(), isNull);

      // Tocar un producto abre la edición rápida (en tablet, el panel de al lado).
      await tester.tap(find.text('Pollo entero a la brasa'));
      await settle(tester);
      if (!tablet) {
        expect(find.text('Más detalles'), findsOneWidget);
        await tester.tap(find.byTooltip('Subir 50 céntimos'));
        await settle(tester);
        expect(find.textContaining('65.50'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (mobile) await _capture(find.byType(BottomSheet), 'carta_rapida');
        await tester.tap(find.text('Más detalles'));
        await settle(tester);
      }
      expect(find.byType(ProductEditorPage), findsOneWidget);
      if (tablet) expect(find.byType(MerchantProductsPage), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Disponible para pedir'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (mobile) await _capture(find.byType(ProductEditorPage), 'carta_editar');
      if (tablet) await _capture(find.byType(MerchantProductsPage), 'carta_tablet');

      // Guardar sin precio marca el error y no sale de la pantalla.
      final price = find.descendant(
        of: find.widgetWithText(AppInput, 'Precio (S/)'),
        matching: find.byType(TextFormField),
      );
      expect(tester.widget<TextFormField>(price).controller!.text, '65.00');
      await tester.enterText(price, '');
      await tester.tap(find.text('Guardar cambios'));
      await settle(tester);
      expect(find.text('Escribe un precio, por ejemplo 12.50.'), findsOneWidget);

      await _go(tester, container, '$_products/nuevo');
      expect(find.text('Agregar a la carta'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (mobile) await _capture(find.byType(ProductEditorPage), 'carta_nuevo');

      await _go(tester, container, '$_products/secciones');
      expect(find.text('Pollos a la brasa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (mobile) await _capture(find.byType(MenuSectionsPage), 'carta_secciones');

      await _go(tester, container, '$_products/importar');
      expect(find.text('Elegir archivo'), findsOneWidget);
      expect(find.text('Guarda la plantilla'), findsOneWidget);
      expect(find.text('Mazamorra morada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (mobile) await _capture(find.byType(ProductImportPage), 'carta_importar');

      await unmountApamuy(tester, container);
    });
  }

  testWidgets('elegir varios y agotarlos de una vez', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    await _go(tester, container, _products);

    await tester.longPress(find.text('Pollo entero a la brasa'));
    await settle(tester);
    expect(find.text('1 elegido'), findsOneWidget);
    await tester.tap(find.text('1/2 pollo a la brasa'));
    await settle(tester);
    expect(find.text('2 elegidos'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsNothing);
    await _capture(find.byType(MerchantProductsPage), 'carta_elegir');

    await tester.tap(find.text('Agotar'));
    await settle(tester);
    expect(find.text('2 elegidos'), findsNothing);
    expect(find.textContaining('Agotado ·'), findsAtLeastNWidgets(2));
    expect(tester.takeException(), isNull);
    await unmountApamuy(tester, container);
  });

  testWidgets('al agotar desde la lista se puede deshacer', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    await _go(tester, container, _products);
    final soldOutBefore = find.textContaining('Agotado ·').evaluate().length;

    await tester.tap(find.bySemanticsLabel('Disponibilidad de Pollo entero a la brasa'));
    await settle(tester);
    expect(find.textContaining('Agotado ·'), findsNWidgets(soldOutBefore + 1));
    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(find.textContaining('Agotado ·'), findsNWidgets(soldOutBefore));
    await unmountApamuy(tester, container);
  });

  testWidgets('salir con cambios sin guardar pregunta antes', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    await _go(tester, container, _products);
    unawaited(container.read(partnerRouterProvider).push('$_products/editar/pr_pollo_entero'));
    await settle(tester);

    final name = find.descendant(of: find.widgetWithText(AppInput, 'Nombre'), matching: find.byType(TextFormField));
    await tester.enterText(name, 'Pollo entero con papas');
    await tester.tap(find.byTooltip('Volver'));
    await settle(tester);
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await settle(tester);
    expect(find.byType(ProductEditorPage), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await settle(tester);
    await tester.tap(find.text('Descartar'));
    await settle(tester);
    expect(find.byType(ProductEditorPage), findsNothing);
    expect(find.byType(MerchantProductsPage), findsOneWidget);
    await unmountApamuy(tester, container);
  });

  testWidgets('la carta vacía muestra las formas de empezar', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    final repo = container.read(menuRepositoryProvider);
    final menu = (await tester.runAsync(() => repo.menu('st_chaski_dorado')))!.getOrThrow();
    await tester.runAsync(() async {
      for (final p in menu.products) {
        await repo.removeProduct(p.id);
      }
    });
    container.read(menuRevisionProvider.notifier).bump();

    await _go(tester, container, _products);
    expect(find.text('Desde Excel o CSV'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsNothing);
    expect(tester.takeException(), isNull);
    await _capture(find.byType(MerchantProductsPage), 'carta_vacia');

    await tester.tap(find.text('Uno por uno'));
    await settle(tester);
    expect(find.text('Agregar a la carta'), findsOneWidget);
    await unmountApamuy(tester, container);
  });
}
