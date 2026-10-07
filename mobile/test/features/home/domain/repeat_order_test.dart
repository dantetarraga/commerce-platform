import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/home/domain/repeat_order.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/domain/repositories/products_repository.dart';
import 'package:chaski/features/products/products.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProducts extends Mock implements ProductsRepository {}

Order _order(List<OrderLine> lines) => Order(
  id: 'or_1',
  code: '#1',
  store: const OrderStore(id: 'st_1', name: 'Doña Rosa'),
  lines: lines,
  subtotal: const Money(0),
  deliveryFee: const Money(0),
  discount: const Money(0),
  total: const Money(0),
  addressTitle: 'Casa',
  addressStreet: 'Jr. Tacna 248',
  payment: const YapePayment(),
  status: OrderStatus.delivered,
  events: const [],
  placedAt: DateTime(2026, 9, 2),
);

const _caldo = Product(
  id: 'pr_caldo',
  storeId: 'st_1',
  storeName: 'Doña Rosa',
  name: 'Caldo de cordero',
  basePrice: Money(1200),
  isAvailable: true,
  variants: [
    ProductVariant(id: 'v_chico', name: 'Chico', price: Money(1200), isAvailable: true),
    ProductVariant(id: 'v_grande', name: 'Grande', price: Money(1600), isAvailable: true),
  ],
  options: [
    ProductOption(
      id: 'o_extra',
      name: 'Extras',
      minSelect: 0,
      maxSelect: 2,
      values: [OptionValue(id: 'x_mote', name: 'Mote', priceDelta: Money(200), isAvailable: true)],
    ),
  ],
);

const _mate = Product(id: 'pr_mate', storeId: 'st_1', storeName: 'Doña Rosa', name: 'Mate de coca', basePrice: Money(300), isAvailable: true);

void main() {
  group('RepeatOrder.rebuild', () {
    test('rearma variante y opciones por nombre con los precios de hoy', () {
      final order = _order(const [
        OrderLine(productId: 'pr_caldo', name: 'Caldo', quantity: 2, total: Money(3600), description: 'Grande · Mote', notes: 'sin ají'),
        OrderLine(productId: 'pr_mate', name: 'Mate', quantity: 1, total: Money(300)),
      ]);
      final result = RepeatOrder.rebuild(order, {'pr_caldo': _caldo, 'pr_mate': _mate}, stamp: 7);

      expect(result.missing, 0);
      final caldo = result.lines.first;
      expect(caldo.variantName, 'Grande');
      expect(caldo.choices.single.label, 'Mote');
      expect(caldo.unitPrice, const Money(1800));
      expect(caldo.quantity.value, 2);
      expect(caldo.notes, 'sin ají');
      expect(caldo.id, 'pr_caldo.7.0');
      expect(result.lines.last.productId, 'pr_mate');
    });

    test('sin nombre guardado, elige la variante del precio pagado', () {
      final order = _order(const [OrderLine(productId: 'pr_caldo', name: 'Caldo', quantity: 1, total: Money(1600))]);
      expect(RepeatOrder.rebuild(order, {'pr_caldo': _caldo}, stamp: 1).lines.single.variantName, 'Grande');
    });

    test('cuenta como faltante lo agotado, lo borrado y lo que no tiene id', () {
      final order = _order(const [
        OrderLine(productId: 'pr_mate', name: 'Mate', quantity: 1, total: Money(300)),
        OrderLine(productId: 'pr_borrado', name: 'Ya no está', quantity: 1, total: Money(500)),
        OrderLine(name: 'Sin id', quantity: 1, total: Money(500)),
        OrderLine(productId: 'pr_caldo', name: 'Caldo', quantity: 1, total: Money(1200)),
      ]);
      const soldOut = Product(id: 'pr_caldo', storeId: 'st_1', storeName: 'Doña Rosa', name: 'Caldo', basePrice: Money(1200), isAvailable: false);
      final result = RepeatOrder.rebuild(order, {'pr_mate': _mate, 'pr_caldo': soldOut}, stamp: 1);
      expect(result.lines.map((l) => l.productId), ['pr_mate']);
      expect(result.missing, 3);
    });

    test('si ninguna variante está disponible, la línea falta', () {
      const allOut = Product(
        id: 'pr_caldo',
        storeId: 'st_1',
        storeName: 'Doña Rosa',
        name: 'Caldo',
        basePrice: Money(1200),
        isAvailable: true,
        variants: [ProductVariant(id: 'v', name: 'Chico', price: Money(1200), isAvailable: false)],
      );
      final order = _order(const [OrderLine(productId: 'pr_caldo', name: 'Caldo', quantity: 1, total: Money(1300))]);
      expect(RepeatOrder.rebuild(order, {'pr_caldo': allOut}, stamp: 1).missing, 1);
    });
  });

  test('call pide cada producto una vez y los que fallan cuentan como faltantes', () async {
    final products = _MockProducts();
    when(() => products.getProduct('pr_mate', near: any(named: 'near'))).thenAnswer((_) async => const Result.ok(_mate));
    when(
      () => products.getProduct('pr_caldo', near: any(named: 'near')),
    ).thenAnswer((_) async => const Result.err(NetworkFailure()));
    final order = _order(const [
      OrderLine(productId: 'pr_mate', name: 'Mate', quantity: 1, total: Money(300)),
      OrderLine(productId: 'pr_mate', name: 'Mate', quantity: 2, total: Money(600)),
      OrderLine(productId: 'pr_caldo', name: 'Caldo', quantity: 1, total: Money(1200)),
    ]);

    final result = await RepeatOrder(products).call(order, near: GeoCoordinates.trusted(-14.79, -71.41));

    expect(result.lines, hasLength(2));
    expect(result.missing, 1);
    verify(() => products.getProduct('pr_mate', near: any(named: 'near'))).called(1);
  });
}
