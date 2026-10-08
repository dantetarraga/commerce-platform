import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/orders/orders_staff.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final order = Order(
    id: 'o1',
    code: '#2481',
    store: const OrderStore(id: 's1', name: 'Picantería Doña Rosa'),
    lines: const [OrderLine(name: 'Caldo', quantity: 2, total: Money(2800), notes: 'sin ají')],
    subtotal: const Money(2800),
    deliveryFee: const Money(300),
    discount: const Money.zero(),
    total: const Money(3100),
    addressTitle: 'Casa',
    addressStreet: 'Jr. Túpac Amaru 214',
    payment: const CashPayment(changeFor: Money(5000)),
    status: OrderStatus.onTheWay,
    events: [OrderEvent(OrderStatus.received, DateTime(2026, 9, 23, 13))],
    placedAt: DateTime(2026, 9, 23, 13),
    notes: 'Tocar el timbre',
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: TicketSection(child: child)),
    ),
  );

  testWidgets('las líneas muestran cantidad, notas y la nota del pedido', (tester) async {
    await pump(tester, StaffOrderLines(order: order, title: 'LO QUE LLEVAS', prices: false, dense: true));
    expect(find.text('LO QUE LLEVAS'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('“sin ají”'), findsOneWidget);
    expect(find.text('Nota: Tocar el timbre'), findsOneWidget);
    expect(find.text('S/ 28.00'), findsNothing);
  });

  testWidgets('el cobro detalla montos y el vuelto que lleva el repartidor', (tester) async {
    await pump(tester, StaffCollectSummary(order: order));
    expect(find.text('S/ 31.00'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Pedido, ')), findsOneWidget);
    expect(find.textContaining('lleva S/'), findsOneWidget);
    expect(find.textContaining('19.00 de vuelto'), findsOneWidget);
  });

  testWidgets('la versión compacta dice cómo cobra y cuánto', (tester) async {
    await pump(tester, StaffCollectSummary.compact(order: order));
    expect(find.text('Cobras · Efectivo · paga con S/ 50.00'), findsOneWidget);
    expect(find.text('S/ 31.00'), findsOneWidget);
  });
}
