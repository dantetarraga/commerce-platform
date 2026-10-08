import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/cart/infrastructure/models/cart_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rosa = CartStore(
    id: 'st_dona_rosa',
    name: 'Picantería Doña Rosa',
    deliveryFee: Money(300),
    minOrderAmount: Money(1000),
    etaMinutes: 25,
  );
  const tanta = CartStore(id: 'st_tanta_wasi', name: 'Tanta Wasi', deliveryFee: Money(250), minOrderAmount: Money(500), etaMinutes: 20);

  CartLine line(String id, {String product = 'pr_caldo', int price = 1400, int qty = 1, String notes = '', List<CartChoice> choices = const []}) =>
      CartLine(
        id: id,
        productId: product,
        name: product,
        unitPrice: Money(price),
        quantity: Quantity.create(qty).valueOrNull!,
        notes: notes,
        choices: choices,
      );

  Cart added(AddToCartResult r) => (r as Added).cart;

  group('Cart', () {
    test('suma subtotal, envío y total', () {
      final cart = added(added(Cart.empty.add(line('a', qty: 2), rosa)).add(line('b', product: 'pr_mate', price: 300), rosa));
      expect(cart.itemCount, 3);
      expect(cart.subtotal, const Money(3100));
      expect(cart.total, const Money(3400));
    });

    test('la misma configuración se fusiona sumando cantidades', () {
      final cart = added(added(Cart.empty.add(line('a'), rosa)).add(line('b', qty: 2), rosa));
      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.quantity.value, 3);
    });

    test('distinta nota u opción crea otra línea', () {
      const mote = CartChoice(optionId: 'op', valueId: 'mote', label: 'Mote', priceDelta: Money(200));
      var cart = added(Cart.empty.add(line('a'), rosa));
      cart = added(cart.add(line('b', notes: 'sin cebolla'), rosa));
      cart = added(cart.add(line('c', choices: [mote]), rosa));
      expect(cart.lines, hasLength(3));
    });

    test('agregar de otro negocio devuelve conflicto y no cambia la bolsa', () {
      final cart = added(Cart.empty.add(line('a'), rosa));
      final result = cart.add(line('b', product: 'pr_pan'), tanta);
      expect(result, isA<StoreConflict>());
      expect((result as StoreConflict).current, rosa);
      expect(cart.replaceWith(line('b', product: 'pr_pan'), tanta).store, tanta);
    });

    test('el pedido mínimo bloquea el checkout y reporta cuánto falta', () {
      final cart = added(Cart.empty.add(line('a', product: 'pr_mate', price: 300), rosa));
      expect(cart.canCheckout, isFalse);
      expect(cart.missingForMinimum, const Money(700));
      expect(cart.minimumProgress, closeTo(0.3, 0.001));
    });

    test('el descuento nunca supera el subtotal', () {
      final cart = added(Cart.empty.add(line('a', price: 300), rosa))
          .applyCoupon(const Coupon(code: 'X', discount: Money(900), label: 'x'));
      expect(cart.discount, const Money(300));
      expect(cart.total, const Money(300)); // solo el envío
    });

    test('quitar y deshacer reinserta la línea en su lugar', () {
      final cart = added(added(Cart.empty.add(line('a'), rosa)).add(line('b', product: 'pr_mate', price: 300), rosa));
      final removed = cart.lines.first;
      final restored = cart.remove(removed.id).restore(removed, 0, rosa);
      expect(restored.lines.first, removed);
      expect(restored.lines, hasLength(2));
    });

    test('quitar la última línea vacía la bolsa (y su negocio)', () {
      final cart = added(Cart.empty.add(line('a'), rosa)).remove('a');
      expect(cart, Cart.empty);
    });
  });

  group('nota para el negocio', () {
    test('se limpia y sobrevive a cambios de líneas y cupón', () {
      final cart = added(Cart.empty.add(line('a'), rosa)).setNote('  tocar el timbre ');
      expect(cart.note, 'tocar el timbre');
      final next = added(cart.add(line('b', product: 'pr_mate'), rosa))
          .applyCoupon(const Coupon(code: 'ESPINAR', discount: Money(300), label: 'S/ 3'))
          .removeCoupon()
          .setQuantity('a', Quantity.create(2).valueOrNull!);
      expect(next.note, 'tocar el timbre');
    });

    test('empezar otra bolsa la descarta', () {
      final cart = added(Cart.empty.add(line('a'), rosa)).setNote('sin ají');
      expect(cart.replaceWith(line('t'), tanta).note, isEmpty);
    });
  });

  group('CartJson', () {
    test('ida y vuelta conserva negocio, líneas, opciones y cupón', () {
      const mote = CartChoice(optionId: 'op', valueId: 'mote', label: 'Mote', priceDelta: Money(200));
      final cart = added(Cart.empty.add(line('a', notes: 'sin cebolla', choices: [mote]), rosa))
          .applyCoupon(const Coupon(code: 'ESPINAR', discount: Money(300), label: 'S/ 3'));
      expect(CartJson.decode(CartJson.encode(cart)), cart);
    });

    test('un documento de otra versión o corrupto devuelve bolsa vacía', () {
      expect(CartJson.decode({'v': 99}), Cart.empty);
      expect(CartJson.decode({'v': 1, 'lines': 'roto'}), Cart.empty);
      expect(CartJson.decode(null), Cart.empty);
    });
  });
}
