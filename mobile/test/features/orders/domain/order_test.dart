import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/infrastructure/models/order_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = DateTime(2026, 9, 23, 19, 2);

  Order order(OrderStatus status, {Courier? courier, PaymentMethod payment = const YapePayment(), DateTime? eta}) => Order(
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
    events: [OrderEvent(OrderStatus.received, placed)],
    placedAt: placed,
    courier: courier,
    estimatedArrival: eta,
  );

  test('los mensajes nombran a quien prepara y a quien reparte', () {
    expect(order(OrderStatus.preparing).headline, 'Rosa está preparando tu pedido');
    const luis = Courier(name: 'Luis Quispe', vehicle: 'Moto roja');
    expect(order(OrderStatus.onTheWay, courier: luis).headline, 'Luis va en camino');
    expect(order(OrderStatus.onTheWay, payment: const CashPayment()).detail, contains('efectivo'));
  });

  test('reached respeta el orden del quipu y cancelado no alcanza nada', () {
    final o = order(OrderStatus.ready);
    expect(o.reached(OrderStatus.preparing), isTrue);
    expect(o.reached(OrderStatus.onTheWay), isFalse);
    expect(order(OrderStatus.cancelled).reached(OrderStatus.received), isFalse);
  });

  test('minutos restantes nunca bajan de 1 mientras está activo', () {
    final now = DateTime(2026, 9, 23, 19, 30);
    expect(order(OrderStatus.onTheWay, eta: now.add(const Duration(minutes: 8))).minutesLeft(now), 8);
    expect(order(OrderStatus.onTheWay, eta: now.subtract(const Duration(minutes: 2))).minutesLeft(now), 1);
    expect(order(OrderStatus.delivered, eta: now).minutesLeft(now), isNull);
  });

  test('OrderJson traduce estados, pagos y el pedido completo', () {
    expect(OrderJson.statusFromJson('COURIER_ASSIGNED'), OrderStatus.courierAssigned);
    expect(OrderJson.statusToJson(OrderStatus.onTheWay), 'ON_THE_WAY');
    expect(OrderJson.paymentFromJson({'type': 'CASH', 'changeFor': {'amount': 5000, 'currency': 'PEN'}}), const CashPayment(changeFor: Money(5000)));
    final parsed = OrderJson.fromJson({
      'id': 'o1',
      'code': '#1',
      'store': {'id': 's1', 'name': 'Rosa', 'ownerName': 'Rosa'},
      'lines': [
        {'productId': 'p', 'name': 'Caldo', 'quantity': 1, 'total': {'amount': 1400, 'currency': 'PEN'}},
      ],
      'subtotal': {'amount': 1400, 'currency': 'PEN'},
      'deliveryFee': {'amount': 300, 'currency': 'PEN'},
      'discount': {'amount': 0, 'currency': 'PEN'},
      'total': {'amount': 1700, 'currency': 'PEN'},
      'address': {'title': 'Casa', 'street': 'Jr. X 1'},
      'payment': {'type': 'PLIN'},
      'status': 'PREPARING',
      'events': [
        {'status': 'RECEIVED', 'at': '2026-09-23T19:02:00Z'},
      ],
      'placedAt': '2026-09-23T19:02:00Z',
    });
    expect(parsed.status, OrderStatus.preparing);
    expect(parsed.payment, const PlinPayment());
    expect(parsed.total, const Money(1700));
    expect(parsed.courier, isNull);
    expect(parsed.tip, const Money.zero()); // pedidos viejos sin propina
  });

  test('la propina viaja en el pedido y en la respuesta', () {
    final parsed = OrderJson.fromJson({
      'id': 'o2',
      'code': '#2',
      'store': {'id': 's1', 'name': 'Rosa'},
      'lines': <Object>[],
      'subtotal': {'amount': 1400, 'currency': 'PEN'},
      'deliveryFee': {'amount': 300, 'currency': 'PEN'},
      'discount': {'amount': 0, 'currency': 'PEN'},
      'tip': {'amount': 200, 'currency': 'PEN'},
      'total': {'amount': 1900, 'currency': 'PEN'},
      'address': {'title': 'Casa', 'street': 'Jr. X 1'},
      'payment': {'type': 'YAPE'},
      'status': 'RECEIVED',
      'events': <Object>[],
      'placedAt': '2026-09-23T19:02:00Z',
    });
    expect(parsed.tip, const Money(200));
    expect(parsed.copyWith(rating: 3).tip, const Money(200));

    const request = PlaceOrderRequest(
      storeId: 's1',
      items: [PlaceOrderItem(productId: 'p', quantity: 1)],
      addressTitle: 'Casa',
      addressStreet: 'Jr. X 1',
      latitude: -14.79,
      longitude: -71.41,
      payment: YapePayment(),
      tip: Money(300),
      notes: 'tocar el timbre',
    );
    final json = OrderJson.requestToJson(request);
    expect(json['tip'], {'amount': 300, 'currency': 'PEN'});
    expect(json['notes'], 'tocar el timbre');
  });
}
