import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/pages/order_help_page.dart';
import 'package:chaski/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

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

  Future<void> pump(WidgetTester tester, Widget page, Order o, {OrdersRepository? repository}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderWatchProvider(o.id).overrideWith((ref) => Stream.value(o)),
          if (repository != null) ordersRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: page),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

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
    expect(find.text('~${Formatters.clock(eta)}'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Luis Quispe'), 100, scrollable: find.byType(Scrollable).last);
    expect(find.text('Luis Quispe'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('¿Algún problema con tu pedido?'), 120, scrollable: find.byType(Scrollable).last);
    expect(find.text('¿Algún problema con tu pedido?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tras calificar, el seguimiento abierto deja de ofrecer calificar', (tester) async {
    final repository = _MockOrdersRepository();
    var rated = false;
    final delivered = order(OrderStatus.delivered, events: [OrderEvent(OrderStatus.received, placed), OrderEvent(OrderStatus.delivered, placed)]);
    when(() => repository.watch('o1')).thenAnswer((_) => Stream.value(rated ? delivered.copyWith(rating: 5) : delivered));
    when(repository.history).thenAnswer((_) async => const Result.ok(OrderLists.empty));
    when(() => repository.rate('o1', rating: 5, comment: any(named: 'comment'))).thenAnswer((_) async {
      rated = true;
      return Result.ok(delivered.copyWith(rating: 5));
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(data: MediaQueryData(disableAnimations: true), child: OrderTrackingPage(orderId: 'o1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(find.text('Calificar pedido'), 100, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Calificar pedido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.bySemanticsLabel(RegExp('^5 de 5 estrellas')));
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    verify(() => repository.rate('o1', rating: 5, comment: any(named: 'comment'))).called(1);
    expect(find.text('Calificar pedido'), findsNothing);
    expect(find.text('Gracias por calificar'), findsOneWidget);

    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
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
    // El aviso llega un cuadro después y crece durante la entrada.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Te escribimos en menos de 10 minutos'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  group('cancelar desde la ayuda', () {
    testWidgets('solo aparece antes de que el negocio empiece a preparar', (tester) async {
      await pump(tester, const OrderHelpPage(orderId: 'o1'), order(OrderStatus.preparing));
      expect(find.text('Cancelar pedido'), findsNothing);
    });

    testWidgets('confirma, cancela y avisa que no se cobró', (tester) async {
      final repository = _MockOrdersRepository();
      when(
        () => repository.cancel('o1', reason: any(named: 'reason')),
      ).thenAnswer((_) async => Result.ok(order(OrderStatus.cancelled)));
      when(repository.history).thenAnswer((_) async => const Result.ok(OrderLists.empty));
      when(() => repository.watch('o1')).thenAnswer((_) => Stream.value(order(OrderStatus.cancelled)));

      await pump(tester, const OrderHelpPage(orderId: 'o1'), order(OrderStatus.received), repository: repository);
      await tester.tap(find.text('Cancelar pedido'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Cancelar tu pedido?'), findsOneWidget);

      await tester.tap(find.text('Sí, cancelar'));
      await tester.pump(const Duration(milliseconds: 400));
      verify(() => repository.cancel('o1', reason: any(named: 'reason'))).called(1);
      // El aviso llega un cuadro después y crece durante la entrada.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Cancelamos tu pedido. No se te cobró nada.'), findsOneWidget);

      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('si ya no se puede, muestra el motivo del backend', (tester) async {
      final repository = _MockOrdersRepository();
      when(() => repository.cancel('o1', reason: any(named: 'reason'))).thenAnswer(
        (_) async => const Result.err(
          BusinessFailure('INVALID_STATUS_TRANSITION', 'El negocio ya está preparando tu pedido: escríbenos para cancelarlo.'),
        ),
      );

      await pump(tester, const OrderHelpPage(orderId: 'o1'), order(OrderStatus.confirmed), repository: repository);
      await tester.tap(find.text('Cancelar pedido'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Sí, cancelar'));
      await tester.pump(const Duration(milliseconds: 400));
      // El aviso llega un cuadro después y crece durante la entrada.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('escríbenos para cancelarlo'), findsOneWidget);

      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
