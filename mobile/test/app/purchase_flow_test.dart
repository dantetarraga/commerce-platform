import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/app/router/routes.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// Recorrido completo con la UI real y el backend fake: descubrir → bolsa →
/// checkout → seguimiento → calificar.
void main() {
  testWidgets('de Cerca a un pedido entregado y calificado', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
    FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : errors.add(d);
    addTearDown(() => FlutterError.onError = original);

    final container = await pumpChaski(tester, signedIn: true);
    final router = container.read(appRouterProvider);

    // ── Cerca ──
    expect(currentPath(container), RoutePaths.home);
    expect(find.text('Volver a pedir'), findsOneWidget); // historial de demo
    // "De tu barrio" queda más abajo, después de los accesos y colecciones.
    await tester.scrollUntilVisible(find.text('De tu barrio'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('De tu barrio'), findsOneWidget);

    // ── Negocio: "+" rápido de un producto sin opciones ──
    router.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': 'st_dona_rosa'}).ignore();
    await settle(tester, frames: 30);
    expect(find.text('Picantería Doña Rosa'), findsWidgets);
    expect(find.text('Atiende Rosa desde 2009'), findsOneWidget);

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
    expect(find.bySemanticsLabel(RegExp('^1 producto')), findsOneWidget); // la posta

    // ── Producto con variante: se elige "Grande" y se agrega ──
    router.pushNamed(ProductDetailPage.name, pathParameters: {'productId': 'pr_caldo_cordero'}).ignore();
    await settle(tester, frames: 30);
    await tester.ensureVisible(find.text('Grande'));
    await settle(tester, frames: 5);
    await tester.tap(find.text('Grande'));
    await settle(tester, frames: 5);
    await tester.tap(find.text('Agregar · '));
    await settle(tester, frames: 30);
    expect(find.byType(ProductDetailPage), findsNothing); // volvió al negocio
    final cart = container.read(cartControllerProvider).value!;
    expect(cart.itemCount, 2);
    expect(cart.lines.any((l) => l.variantName == 'Grande'), isTrue);

    // ── Bolsa → checkout ──
    expect(find.bySemanticsLabel(RegExp('^2 productos')), findsOneWidget);
    await tester.tap(find.text('Ver bolsa'));
    await settle(tester);
    expect(find.text('Tu bolsa'), findsOneWidget);
    await tester.tap(find.textContaining('Continuar'));
    await settle(tester, frames: 30);
    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(find.text('Elige dónde te lo llevamos.'), findsOneWidget);

    // Sin dirección: se agrega desde el checkout.
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
    await tester.tap(find.textContaining('Pedir ahora'));
    await settle(tester, frames: 60); // pedido + pantalla de confirmación
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await tester.tap(find.text('Seguir mi pedido'));
    await settle(tester, frames: 5);

    expect(find.byType(OrderTrackingPage), findsOneWidget);
    // Según el reloj del fake, ya puede ir en "recibido" o "confirmado".
    expect(find.textContaining(RegExp('Recibimos tu pedido|confirmó tu pedido')), findsWidgets);
    expect(container.read(cartControllerProvider).value?.isEmpty, isTrue);

    // ── Seguimiento: el pedido avanza solo (paso de 2 s en el fake) ──
    await settle(tester, frames: 50, step: const Duration(milliseconds: 100)); // ~5 s
    expect(find.text('Rosa está preparando tu pedido'), findsOneWidget);

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
    // Se restaura antes de los expect finales: el framework lo exige.
    FlutterError.onError = original;
    expect(errors.map((e) => e.exceptionAsString()).toList(), isEmpty);
  });
}
