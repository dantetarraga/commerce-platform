import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/app/router/routes.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/home/home.dart';
import 'package:chaski/features/home/presentation/widgets/home_editorial.dart';
import 'package:chaski/features/orders/orders_customer.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/design_capture.dart';

/// Recorrido completo con la UI real y el backend fake: descubrir → bolsa →
/// checkout → seguimiento → calificar.
void main() {
  setUpAll(loadDesignFonts);
  for (final (name, size, scale, brightness) in [
    ('movil', const Size(390, 844), 1.0, Brightness.light),
    ('compacto', const Size(320, 720), 1.4, Brightness.light),
    ('oscuro', const Size(390, 844), 1.0, Brightness.dark),
  ]) {
    testWidgets('de Cerca a un pedido entregado y calificado: $name', (tester) async {
      final container = await pumpChaski(tester, signedIn: true, size: size, textScale: scale, brightness: brightness);
      final router = container.read(appRouterProvider);

      expect(currentPath(container), RoutePaths.home);
      await tester.scrollUntilVisible(find.text('Volver a pedir'), 250, scrollable: find.byType(Scrollable).first);
      expect(find.text('Volver a pedir'), findsOneWidget); // historial de demo
      if (name == 'movil') await captureCity(tester, 'inicio_volver');
      // "Cerca de ti" queda más abajo, después de promos y recomendados.
      await tester.scrollUntilVisible(find.text('Cerca de ti'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Cerca de ti'), findsOneWidget);
      if (name == 'movil') {
        await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -300));
        await settle(tester, frames: 10);
        await captureCity(tester, 'inicio_barrio');
      }

      // Negocio: "+" rápido de un producto sin opciones.
      router.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': 'st_dona_rosa'}).ignore();
      await settle(tester, frames: 30);
      expect(find.text('Picantería Doña Rosa'), findsWidgets);
      expect(find.text('Atiende Rosa desde 2009'), findsOneWidget);
      if (name == 'movil') await captureCity(tester, 'restaurante');

      final mate = find.text('Mate de coca');
      await tester.scrollUntilVisible(mate, 300, scrollable: find.byType(Scrollable).first);
      await settle(tester, frames: 5);
      final quickAdd = find.descendant(
        of: find.ancestor(of: mate, matching: find.byType(AppProductCard)),
        matching: find.byType(QuickAddButton),
      );
      await tester.tap(quickAdd);
      await settle(tester);
      expect(container.read(cartControllerProvider).value?.itemCount, 1);
      expect(find.bySemanticsLabel(RegExp('^1 producto')), findsOneWidget); // la barra de compra

      // Producto con variante: se elige "Grande" y se agrega.
      router.pushNamed(ProductDetailPage.name, pathParameters: {'productId': 'pr_caldo_cordero'}).ignore();
      await settle(tester, frames: 30);
      if (name == 'movil') await captureCity(tester, 'producto');
      await tester.scrollUntilVisible(find.text('Grande'), 180, scrollable: find.byType(Scrollable).first);
      await settle(tester, frames: 5);
      await tester.tap(find.text('Grande'));
      await settle(tester, frames: 5);
      await tester.tap(find.text('Agregar · '));
      await settle(tester, frames: 30);
      expect(find.byType(ProductDetailPage), findsNothing); // volvió al negocio
      final cart = container.read(cartControllerProvider).value!;
      expect(cart.itemCount, 2);
      expect(cart.lines.any((l) => l.variantName == 'Grande'), isTrue);

      expect(find.bySemanticsLabel(RegExp('^2 productos')), findsOneWidget);
      await tester.tap(find.text('Ver bolsa'));
      await settle(tester);
      expect(find.text('Tu bolsa'), findsOneWidget);
      if (name == 'movil') await captureCity(tester, 'bolsa');
      await tester.tap(find.textContaining('Continuar'));
      await settle(tester, frames: 30);
      expect(find.byType(CheckoutPage), findsOneWidget);
      expect(find.text('Elige dónde te lo llevamos.'), findsOneWidget);

      // Sin dirección: se agrega desde el checkout.
      await tester.ensureVisible(find.text('¿Dónde te lo llevamos?'));
      await settle(tester, frames: 5);
      await tester.tap(find.text('¿Dónde te lo llevamos?'));
      await settle(tester);
      await tester.tap(find.text('Agregar dirección'));
      await settle(tester, frames: 30);
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AppInput, 'Calle y número'), matching: find.byType(TextFormField)),
        'Jr. Túpac Amaru 214',
      );
      await tester.tap(find.text('Guardar dirección'));
      await settle(tester, frames: 30);
      expect(find.byType(CheckoutPage), findsOneWidget);
      expect(find.textContaining('Casa'), findsOneWidget);

      // Pago con Yape (hoja de pago) y pedir.
      await tester.ensureVisible(find.text('¿Cómo pagas?'));
      await settle(tester, frames: 5);
      await tester.tap(find.text('¿Cómo pagas?'));
      await settle(tester);
      await tester.tap(find.text('Yape').last);
      await settle(tester, frames: 5);
      await tester.tap(find.text('Usar Yape'));
      await settle(tester);
      if (name == 'movil') await captureCity(tester, 'checkout');
      if (name == 'movil') {
        await tester.drag(find.byType(ListView).first, const Offset(0, 800));
        await settle(tester, frames: 5);
        await captureCity(tester, 'checkout_cabecera');
      }
      await tester.tap(find.textContaining('Pedir ahora'));
      await settle(tester, frames: 60); // pedido + pantalla de confirmación
      expect(find.text('Seguir mi pedido'), findsOneWidget);
      await tester.tap(find.text('Seguir mi pedido'));
      await settle(tester, frames: 5);

      expect(find.byType(OrderTrackingPage), findsOneWidget);
      if (name == 'movil') await captureCity(tester, 'seguimiento');
      // Según el reloj del fake, ya puede ir en "recibido" o "confirmado".
      expect(find.textContaining(RegExp('Recibimos tu pedido|confirmó tu pedido')), findsWidgets);
      expect(container.read(cartControllerProvider).value?.isEmpty, isTrue);

      // Seguimiento: el pedido avanza solo (paso de 2 s en el fake).
      await settle(tester, frames: 50, step: const Duration(milliseconds: 100)); // ~5 s
      expect(find.text('Rosa está preparando tu pedido'), findsOneWidget);

      // Con el pedido en curso, la portada del inicio es su seguimiento.
      container.read(appRouterProvider).goNamed(HomePage.name);
      await settle(tester, frames: 5);
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 4000));
      await settle(tester, frames: 10);
      expect(find.byType(ActiveOrderCover), findsOneWidget);
      if (name == 'movil') await captureCity(tester, 'inicio_pedido');
      await tester.tap(find.byTooltip('Ver mapa'));
      await settle(tester, frames: 5);
      expect(find.byType(OrderTrackingPage), findsOneWidget);

      await settle(tester, frames: 170, step: const Duration(milliseconds: 100)); // ~17 s más
      expect(find.text('Entregado. ¡Buen provecho!'), findsOneWidget);
      await settle(tester);
      expect(find.text('¿Qué tal estuvo?'), findsWidgets); // hoja de calificación

      await tester.tap(find.bySemanticsLabel(RegExp('^5 de 5 estrellas')));
      await settle(tester, frames: 5);
      await tester.tap(find.text('Enviar'));
      await settle(tester);
      // Historial fresco del repositorio: el fake responde con demoras, así que
      // se avanza el reloj de prueba hasta que llegue.
      List<Order>? history;
      container.read(ordersRepositoryProvider).history().then((r) => history = r.getOrThrow()).ignore();
      for (var i = 0; i < 40 && history == null; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final order = history!.first;
      expect(order.status, OrderStatus.delivered);
      expect(order.rating, 5);

      AppToast.dismiss();
      await unmountChaski(tester, container);
      expect(tester.takeException(), isNull);
    });
  }
}
