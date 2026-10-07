import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = DateTime(2026, 9, 23, 12);
  final here = GeoCoordinates.trusted(-14.79, -71.41);

  StaffOrder staff(String id, OrderStatus status, {List<OrderEvent> events = const [], DateTime? eta}) => StaffOrder(
    order: Order(
      id: id,
      code: '#$id',
      store: const OrderStore(id: 's1', name: 'Doña Rosa'),
      lines: const [],
      subtotal: const Money(2000),
      deliveryFee: const Money(300),
      discount: const Money.zero(),
      total: const Money(2300),
      addressTitle: 'Casa',
      addressStreet: 'Jr. Lima 1',
      payment: const YapePayment(),
      status: status,
      events: events,
      placedAt: placed,
      estimatedArrival: eta,
    ),
    customerName: 'Ana',
    customerPhone: '984123456',
    deliveryLocation: here,
    pickup: Pickup(address: 'Plaza', location: here),
    distanceMeters: 800,
  );

  test('agrupa los pedidos en las tres columnas del riel', () {
    final board = MerchantBoardColumn.group([
      staff('1', OrderStatus.received),
      staff('2', OrderStatus.preparing),
      staff('3', OrderStatus.courierAssigned),
      staff('4', OrderStatus.confirmed),
      staff('5', OrderStatus.delivered),
    ]);
    expect(board[MerchantBoardColumn.fresh]!.map((o) => o.id), ['1']);
    expect(board[MerchantBoardColumn.cooking]!.map((o) => o.id), ['2', '4']);
    expect(board[MerchantBoardColumn.ready]!.map((o) => o.id), ['3']);
    expect(MerchantBoardColumn.of(OrderStatus.cancelled), isNull);
  });

  test('avance en el fogón hacia la hora prometida', () {
    final accepted = placed.add(const Duration(minutes: 2));
    final order = staff(
      '1',
      OrderStatus.preparing,
      events: [OrderEvent(OrderStatus.confirmed, accepted)],
      eta: accepted.add(const Duration(minutes: 35)), // listo a los 20 min
    );
    final half = PrepProgress.of(order, accepted.add(const Duration(minutes: 10)));
    expect(half.startedAt, accepted);
    expect(half.fraction, closeTo(0.5, 0.001));
    expect(half.dueLabel, 'faltan 10 min');
    final late = PrepProgress.of(order, accepted.add(const Duration(minutes: 23)));
    expect(late.isLate, isTrue);
    expect(late.fraction, 1);
    expect(late.dueLabel, 'se pasó 3 min');
    final unknown = PrepProgress.of(staff('2', OrderStatus.preparing), placed);
    expect(unknown.startedAt, placed);
    expect(unknown.fraction, isNull);
    expect(unknown.dueLabel, isNull);
  });

  test('comandas del día sin las canceladas', () {
    const summary = MerchantSummary(deliveredCount: 5, cancelledCount: 2, activeCount: 3, sales: Money(10000));
    expect(summary.totalCount, 8);
  });

  test('un pedido chico va en una bolsa', () {
    expect(staff('1', OrderStatus.ready).bagCount, 1);
  });
}
