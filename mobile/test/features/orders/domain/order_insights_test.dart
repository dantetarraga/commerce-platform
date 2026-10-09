import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = DateTime(2026, 9, 23, 19);

  Order order(
    OrderStatus status, {
    PaymentMethod payment = const YapePayment(),
    List<OrderEvent> events = const [],
    DateTime? eta,
    Courier? courier,
  }) => Order(
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
    payment: payment,
    status: status,
    events: events,
    placedAt: placed,
    estimatedArrival: eta,
    courier: courier,
  );

  test('código corto, subtotal sin envío y vuelto', () {
    final o = order(OrderStatus.onTheWay, payment: const CashPayment(changeFor: Money(5000)));
    expect(o.shortCode, '2481');
    expect(o.itemsSubtotal, const Money(2800));
    expect(o.changeDue, const Money(1900));
    expect(order(OrderStatus.onTheWay, payment: const CashPayment(changeFor: Money(2000))).changeDue, isNull);
    expect(order(OrderStatus.onTheWay, payment: const CashPayment()).changeDue, isNull);
    expect(order(OrderStatus.onTheWay).changeDue, isNull);
  });

  test('cómo cobra el socio', () {
    expect(const CashPayment(changeFor: Money(5000)).collectLabel, 'Efectivo · paga con S/ 50.00');
    expect(const CashPayment().collectLabel, 'Efectivo');
    expect(const YapePayment().collectLabel, 'Yape');
  });

  test('hora de recojo y avance sobre la ruta', () {
    final left = placed.add(const Duration(minutes: 20));
    final o = order(
      OrderStatus.onTheWay,
      events: [OrderEvent(OrderStatus.onTheWay, left)],
      eta: left.add(const Duration(minutes: 10)),
    );
    expect(o.pickedUpAt, left);
    expect(o.routeProgress(left.add(const Duration(minutes: 5))), closeTo(0.5, 0.001));
    expect(o.routeProgress(left), 0.05);
    expect(o.routeProgress(left.add(const Duration(hours: 1))), 0.95);
    expect(order(OrderStatus.preparing).routeProgress(placed), 0);
    expect(order(OrderStatus.delivered).routeProgress(placed), 1);
    expect(order(OrderStatus.onTheWay).routeProgress(placed), 0.05);
  });

  test('paso de la portada del pedido activo', () {
    final now = DateTime(2026, 9, 23, 19, 30);
    expect(order(OrderStatus.confirmed).activeStep(now), 0);
    expect(order(OrderStatus.ready).activeStep(now), 1);
    expect(order(OrderStatus.onTheWay, eta: now.add(const Duration(minutes: 10))).activeStep(now), 2);
    expect(order(OrderStatus.onTheWay, eta: now.add(const Duration(minutes: 2))).activeStep(now), 3);
    expect(activeStepLabels[order(OrderStatus.delivered).activeStep(now)], 'Llegando');
    // Hasta que el negocio lo acepta, el primer paso dice "Recibido".
    expect(activeStepLabelsFor(OrderStatus.received).first, 'Recibido');
    expect(activeStepLabelsFor(OrderStatus.confirmed).first, 'Confirmado');
  });

  test('iniciales del repartidor y etapas del estado', () {
    expect(const Courier(name: 'Luis Quispe Mamani', vehicle: 'Moto').initials, 'LQ');
    expect(const Courier(name: 'luis', vehicle: 'Moto').initials, 'L');
    expect(OrderStatus.ready.stage, 2);
    expect(OrderStatus.onTheWay.stage, 3);
    expect(OrderStatus.cancelled.stage, OrderStatus.stageCount - 1);
  });

  test('etiquetas de estado para la UI', () {
    expect(OrderStatus.onTheWay.tag, 'EN CAMINO');
    expect(OrderStatus.ready.label, 'Listo para salir');
    expect(OrderStatus.preparing.summaryLabel, 'En curso');
    expect(OrderStatus.ready.partnerLabel, 'Listo para recoger');
    const luis = Courier(name: 'Luis Quispe', vehicle: 'Moto');
    expect(order(OrderStatus.onTheWay, courier: luis).stepTitle(OrderStatus.onTheWay), 'Luis va en camino');
    expect(order(OrderStatus.ready).stepTitle(OrderStatus.preparing), 'Preparado por Rosa');
  });
}
