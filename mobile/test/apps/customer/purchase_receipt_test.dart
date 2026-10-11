import 'package:apamuy/apps/customer/shell/purchase_bar/purchase_bar_controller.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 10, 10, 13);

  CartLine line(
    String id, {
    int qty = 1,
    String? variant,
    List<CartChoice> choices = const [],
  }) => CartLine(
    id: id,
    productId: 'p_$id',
    name: 'Pollo a la brasa ¼',
    unitPrice: const Money(1800),
    quantity: Quantity.create(qty).valueOrNull!,
    variantName: variant,
    choices: choices,
  );

  Cart cart(List<CartLine> lines) => Cart(lines: lines);

  test('una línea nueva sale en la boleta con su detalle y su precio', () {
    final receipt = receiptFor(
      cart([line('a')]),
      cart([
        line('a'),
        line(
          'b',
          qty: 2,
          variant: 'Pierna',
          choices: const [
            CartChoice(
              optionId: 'o',
              valueId: 'v',
              label: 'Papas nativas',
              priceDelta: Money(0),
            ),
          ],
        ),
      ]),
      id: 3,
      at: at,
    )!;
    expect(receipt.id, 3);
    expect(receipt.title, '2 × Pollo a la brasa ¼');
    expect(receipt.detail, 'Pierna · Papas nativas');
    expect(receipt.price, const Money(3600));
  });

  test('sumar unidades a una línea muestra solo lo agregado', () {
    final receipt = receiptFor(
      cart([line('a', qty: 2)]),
      cart([line('a', qty: 3)]),
      id: 1,
      at: at,
    )!;
    expect(receipt.title, '1 × Pollo a la brasa ¼');
    expect(receipt.detail, isNull);
    expect(receipt.price, const Money(1800));
  });

  test('la primera vez (sin bolsa anterior) también cuenta', () {
    expect(
      receiptFor(null, cart([line('a')]), id: 1, at: at)?.title,
      '1 × Pollo a la brasa ¼',
    );
  });

  test('quitar o bajar unidades no imprime boleta', () {
    expect(
      receiptFor(cart([line('a', qty: 2)]), cart([line('a')]), id: 1, at: at),
      isNull,
    );
    expect(
      receiptFor(
        cart([line('a'), line('b')]),
        cart([line('a')]),
        id: 1,
        at: at,
      ),
      isNull,
    );
  });
}
