import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/pages/order_help_page.dart';
import 'package:chaski/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/features/orders/presentation/widgets/order_bits.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = DateTime(2026, 9, 23, 13, 2);

  Order order(OrderStatus status, {List<OrderEvent>? events, Courier? courier, DateTime? eta}) => Order(
    id: 'o1',
    code: '#2481',
    store: const OrderStore(id: 's1', name: 'Picantería Doña Rosa', ownerName: 'Rosa'),
    lines: const [OrderLine(name: 'Caldo', quantity: 2, total: Money(2800))],
    subtotal: const Money(2800),
    deliveryFee: const Money(300),
    discount: const Money.zero(),
    total: const Money(3100),
    addressTitle: 'Casa',
    addressStreet: 'Jr. Túpac Amaru 214',
    payment: const YapePayment(),
    status: status,
    events: events ?? [OrderEvent(OrderStatus.received, placed)],
    placedAt: placed,
    courier: courier,
    estimatedArrival: eta,
  );

  Future<void> pump(WidgetTester tester, Widget page, Order o) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [orderWatchProvider(o.id).overrideWith((ref) => Stream.value(o))],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: page),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('clock12 da la hora como se dice', () {
    expect(clock12(DateTime(2026, 1, 1, 13, 12)), '1:12 pm');
    expect(clock12(DateTime(2026, 1, 1, 0, 5)), '12:05 am');
    expect(clock12(DateTime(2026, 1, 1, 12)), '12:00 pm');
  });

  testWidgets('el seguimiento muestra la ETA, cada paso con su hora y la ayuda', (tester) async {
    final eta = DateTime.now().add(const Duration(minutes: 9));
    final confirmedAt = DateTime(2026, 9, 23, 13, 12);
    final o = order(
      OrderStatus.onTheWay,
      courier: const Courier(name: 'Luis Quispe', vehicle: 'Moto roja'),
      eta: eta,
      events: [
        OrderEvent(OrderStatus.received, placed),
        OrderEvent(OrderStatus.confirmed, confirmedAt),
        OrderEvent(OrderStatus.onTheWay, DateTime.now()),
      ],
    );
    await pump(tester, const OrderTrackingPage(orderId: 'o1'), o);

    expect(find.text('Llega en'), findsOneWidget);
    expect(find.text('EN CAMINO'), findsOneWidget);
    expect(find.text('1:12 pm'), findsOneWidget);
    expect(find.text('~${clock12(eta)}'), findsOneWidget);
    expect(find.text('Luis Quispe'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('¿Algún problema con tu pedido?'), 120, scrollable: find.byType(Scrollable).last);
    expect(find.text('¿Algún problema con tu pedido?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('la ayuda lista los motivos y envía la descripción', (tester) async {
    await pump(tester, const OrderHelpPage(orderId: 'o1'), order(OrderStatus.delivered));

    expect(find.text('Picantería Doña Rosa · #2481'), findsOneWidget);
    for (final reason in ['Falta un producto', 'Llegó dañado o equivocado', 'Me cobraron mal', 'Nunca llegó', 'Otro']) {
      expect(find.text(reason), findsOneWidget);
    }
    expect(find.text('Respondemos en menos de 10 minutos, de 7 am a 11 pm.'), findsOneWidget);

    await tester.tap(find.text('Falta un producto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextField), 'Faltó la gaseosa');
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Te escribimos en menos de 10 minutos'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
