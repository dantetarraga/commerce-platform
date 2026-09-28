import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/home/presentation/widgets/home_sections.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/design_capture.dart';

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 30 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -160));
    await settle(tester, frames: 5);
  }
  expect(target.hitTestable(), findsWidgets);
}

void main() {
  setUpAll(loadDesignFonts);

  for (final scale in [1.0, 1.4]) {
    testWidgets('agrega desde las promos, la bolsa cuenta y la búsqueda sigue a mano, escala $scale', (tester) async {
      final container = await pumpChaski(tester, signedIn: true, size: Size(scale > 1 ? 320 : 390, 844), textScale: scale, disableAnimations: scale > 1);
      final buttons = find.descendant(of: find.byType(PromoCarouselSection), matching: find.byType(QuickAddButton));
      await reveal(tester, buttons);
      final quick = buttons.hitTestable().first;
      final card = tester.widget<AppProductCard>(find.ancestor(of: quick, matching: find.byType(AppProductCard)).first);
      await tester.tap(quick);
      await settle(tester, frames: 30);
      final cart = container.read(cartControllerProvider).value!;
      expect(cart.lines.any((line) => line.productId == card.data.id), isTrue);
      // La bolsa es una pestaña con contador; arriba queda la barra compacta.
      expect(find.bySemanticsLabel(RegExp(r'^Bolsa, \d+ productos?')), findsOneWidget);
      // El aviso "va en tu bolsa" baja sobre la cabecera unos segundos y se va solo.
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.bySemanticsLabel(RegExp('^Entregar en')).hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Buscar').hitTestable().first);
      await settle(tester);
      expect(find.byType(ExplorePage), findsOneWidget);
      expect(container.read(cartControllerProvider).value!.lines.any((line) => line.productId == card.data.id), isTrue);
      expect(tester.takeException(), isNull);
      await unmountChaski(tester, container);
      await tester.pump(const Duration(seconds: 12));
    });
  }

  testWidgets('una categoría fotográfica abre su catálogo', (tester) async {
    final container = await pumpChaski(tester, signedIn: true, disableAnimations: true);
    final category = find.bySemanticsLabel('Explorar Restaurantes');
    await reveal(tester, category);
    await tester.tap(category);
    await settle(tester);
    expect(find.byType(CategoryStoresPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountChaski(tester, container);
    await tester.pump(const Duration(seconds: 12));
  });
}
