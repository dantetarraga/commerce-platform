import 'package:apamuy/apps/customer/shell/purchase_bar/purchase_bar_controller.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = DateTime(2026, 9, 23, 13, 2);

  Order order(OrderStatus status) => Order(
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
    events: [OrderEvent(OrderStatus.received, placed)],
    placedAt: placed,
  );

  test('la franja del pedido lleva el mismo tramo que el riel del seguimiento', () {
    int? stageOf(OrderStatus status) => switch (purchaseBarStateFor(Cart.empty, order(status), placed)) {
      PurchaseBarOrder(:final stage) => stage,
      _ => null,
    };
    expect(stageOf(OrderStatus.received), 0);
    expect(stageOf(OrderStatus.ready), 1);
    expect(stageOf(OrderStatus.onTheWay), 2);
    expect(stageOf(OrderStatus.delivered), 3);
    expect(purchaseBarStateFor(Cart.empty, order(OrderStatus.cancelled), placed), isA<PurchaseBarHidden>());
  });
}
