import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/features/home/presentation/widgets/active_order_cover/active_order_cover.dart';
import 'package:apamuy/features/notifications/notifications.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/design_capture.dart';

/// Capturas de las pantallas del pedido para revisar el diseño. Solo corre con
/// `flutter test test/apps/order_screens_capture_test.dart --update-goldens --dart-define=CAPTURE_ORDER=true`
/// y deja los PNG en `build/capturas/`.
void main() {
  const capture = bool.fromEnvironment('CAPTURE_ORDER');
  setUpAll(loadDesignFonts);

  final now = DateTime.now();
  final placed = now.subtract(const Duration(minutes: 14));
  const luis = Courier(name: 'Luis Quispe', vehicle: 'Moto roja', since: 2023);

  Order order(
    String id,
    OrderStatus status, {
    String store = 'Picantería Doña Rosa',
    String owner = 'Rosa',
    DateTime? at,
    int? rating,
    Courier? courier,
    int total = 4600,
  }) {
    final start = at ?? placed;
    final steps = OrderStatus.timeline.takeWhile((s) => s.index <= status.index && status != OrderStatus.cancelled).toList();
    return Order(
      id: id,
      code: '#${2480 + id.hashCode % 9}',
      store: OrderStore(id: 's-$id', name: store, ownerName: owner),
      lines: const [
        OrderLine(name: 'Menú del día', description: 'Tallarín saltado', quantity: 1, total: Money(1200)),
        OrderLine(name: 'Caldo de cordero', description: 'Regular', quantity: 2, total: Money(2800)),
        OrderLine(name: 'Mate de coca', quantity: 1, total: Money(300)),
      ],
      subtotal: const Money(4300),
      deliveryFee: const Money(300),
      discount: const Money.zero(),
      total: Money(total),
      addressTitle: 'Casa',
      addressStreet: 'Jirón Cusco 210',
      payment: const YapePayment(),
      status: status,
      events: [
        for (final (i, s) in steps.indexed) OrderEvent(s, start.add(Duration(minutes: i * 3))),
        if (status == OrderStatus.cancelled) ...[OrderEvent(OrderStatus.received, start), OrderEvent(OrderStatus.cancelled, start.add(const Duration(minutes: 2)))],
      ],
      placedAt: start,
      courier: courier,
      estimatedArrival: status.isFinal ? null : now.add(const Duration(minutes: 9)),
      rating: rating,
    );
  }

  final live = order('o1', OrderStatus.onTheWay, courier: luis);
  final cooking = order('o2', OrderStatus.preparing);
  final delivered = order('o3', OrderStatus.delivered, courier: luis);
  final past = [
    order('p1', OrderStatus.delivered, store: 'Pollería El Chaski Dorado', owner: 'Julián', at: now.subtract(const Duration(days: 1)), rating: 5, total: 6450),
    order('p2', OrderStatus.delivered, store: 'Cafetería Qente', owner: 'Ana', at: now.subtract(const Duration(days: 3)), total: 1890),
    order('p3', OrderStatus.cancelled, store: 'Pizzería Don Lucho', owner: 'Lucho', at: now.subtract(const Duration(days: 6)), total: 3900),
  ];

  Future<void> pump(WidgetTester tester, Widget home, {List<Order> orders = const []}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeBackendProvider.overrideWithValue(FakeBackend(latency: Duration.zero)),
          for (final o in [...orders, ...past]) orderWatchProvider(o.id).overrideWith((ref) => Stream.value(o)),
          ordersHistoryProvider.overrideWith((ref) async => OrderLists(active: [cooking], past: past)),
        ],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.light(), home: home),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(Overlay).first, matchesGoldenFile('../../build/capturas/$name.png'));
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('seguimiento, historial y calificar', (tester) async {
    await pump(tester, OrderTrackingPage(orderId: live.id), orders: [live]);
    await shot(tester, '1_seguimiento_en_camino');
    await tester.tap(find.text('Historial ›'));
    await tester.pump();
    await shot(tester, '2_seguimiento_historial');
    await done(tester);

    await pump(tester, OrderTrackingPage(orderId: cooking.id), orders: [cooking]);
    await shot(tester, '3_seguimiento_preparando');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, '4_seguimiento_boleta');
    await done(tester);

    await pump(tester, OrderTrackingPage(orderId: delivered.id), orders: [delivered]);
    await tester.scrollUntilVisible(find.text('Calificar pedido'), 120, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Calificar pedido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, '5_calificar');
    await tester.tap(find.bySemanticsLabel(RegExp('^5 de 5 estrellas')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Llegó caliente'));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '5b_calificar_elegido');
    await done(tester);
  }, skip: !capture);

  testWidgets('mis pedidos y ayuda', (tester) async {
    await pump(tester, const OrdersPage(onOpenStore: _noop), orders: [cooking]);
    await shot(tester, '6_mis_pedidos');
    await done(tester);

    await pump(tester, OrderHelpPage(orderId: cooking.id), orders: [cooking]);
    await shot(tester, '7_ayuda');
    await done(tester);
  }, skip: !capture);

  testWidgets('inicio, franja sobre el menú y avisos', (tester) async {
    await pump(
      tester,
      Scaffold(
        body: SafeArea(child: SingleChildScrollView(child: ActiveOrderCover(order: live))),
      ),
      orders: [live],
    );
    await shot(tester, '8_inicio_pedido');
    await done(tester);

    await pump(
      tester,
      Scaffold(
        body: const Center(child: Text('Buscar')),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: AppPurchaseBar(
                state: PurchaseBarOrder(message: live.headline, eta: '9 min', stage: OrderProgressRail.stageOf(live.status)),
                onTap: () {},
              ),
            ),
            AppNavigationDock(index: 1, onSelected: (_) {}, onBag: () {}, liveOrder: true),
          ],
        ),
      ),
    );
    await shot(tester, '9_franja_menu');
    await done(tester);

    await pump(tester, const NotificationsPage());
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '10_avisos');
    await done(tester);
  }, skip: !capture);
}

void _noop(String _) {}
