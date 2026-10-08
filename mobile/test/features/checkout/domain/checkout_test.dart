import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/features/addresses/domain/address.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const store = CartStore(id: 's1', name: 'Doña Rosa', deliveryFee: Money(300), minOrderAmount: Money(1000), etaMinutes: 25);
  final cart = Cart(
    store: store,
    lines: [
      CartLine(
        id: 'l1',
        productId: 'pr_caldo',
        name: 'Caldo',
        unitPrice: const Money(1400),
        quantity: Quantity.create(2).valueOrNull!,
        variantId: 'va_grande',
        choices: const [CartChoice(optionId: 'op', valueId: 'ov_mote', label: 'Mote', priceDelta: Money(200))],
        notes: 'sin cebolla',
      ),
    ],
    coupon: const Coupon(code: 'ESPINAR', discount: Money(300), label: 'S/ 3'),
  );
  final address = Address(
    id: 'a1',
    kind: AddressKind.home,
    street: 'Jr. Túpac Amaru 214',
    reference: 'Puerta verde',
    coordinates: GeoCoordinates.trusted(-14.79, -71.41),
  );

  test('sin dirección ni pago lista lo que falta, en orden', () {
    expect(const CheckoutDraft().issues(cart, null), [CheckoutIssue.missingAddress, CheckoutIssue.missingPayment]);
  });

  test('una bolsa bajo el mínimo no se puede confirmar', () {
    final small = Cart(store: store, lines: [cart.lines.first.copyWith(quantity: Quantity.one)].map((l) => CartLine(
      id: l.id, productId: l.productId, name: l.name, unitPrice: const Money(500), quantity: Quantity.one,
    )).toList());
    expect(const CheckoutDraft(paymentKind: PaymentKind.yape).issues(small, address), [CheckoutIssue.belowMinimum]);
  });

  test('el efectivo debe cubrir el total', () {
    // total = 2800 + 300 - 300 = 2800
    const tooLow = CheckoutDraft(paymentKind: PaymentKind.cash, cashChangeFor: Money(2000));
    const enough = CheckoutDraft(paymentKind: PaymentKind.cash, cashChangeFor: Money(5000));
    expect(tooLow.issues(cart, address), [CheckoutIssue.cashTooLow]);
    expect(enough.issues(cart, address), isEmpty);
  });

  test('arma el pedido con opciones, nota, cupón y horario', () {
    final at = DateTime(2026, 9, 23, 13, 30);
    final request = CheckoutDraft(paymentKind: PaymentKind.plin, deliveryTime: DeliverAt(at)).toRequest(cart, address);
    expect(request.storeId, 's1');
    expect(request.items.single.optionValueIds, ['ov_mote']);
    expect(request.items.single.variantId, 'va_grande');
    expect(request.items.single.notes, 'sin cebolla');
    expect(request.items.single.quantity, 2);
    expect(request.payment, const PlinPayment());
    expect(request.couponCode, 'ESPINAR');
    expect(request.scheduledFor, at);
    expect(request.addressReference, 'Puerta verde');
  });

  test('cambiar a otro medio de pago descarta el vuelto', () {
    const draft = CheckoutDraft(paymentKind: PaymentKind.cash, cashChangeFor: Money(5000));
    final next = draft.copyWith(paymentKind: PaymentKind.yape, clearChange: true);
    expect(next.cashChangeFor, isNull);
    expect(next.payment, const YapePayment());
  });

  group('propina', () {
    test('empieza en cero: nada se suma sin que lo elijas', () {
      expect(const CheckoutDraft().tip, const Money.zero());
      expect(const CheckoutDraft().total(cart), cart.total);
    });

    test('el total suma la propina y va en el pedido', () {
      const draft = CheckoutDraft(paymentKind: PaymentKind.yape, tip: Money(200));
      expect(draft.total(cart), Money(cart.total.cents + 200));
      expect(draft.toRequest(cart, address).tip, const Money(200));
    });

    test('una bolsa vacía no cobra propina', () {
      expect(const CheckoutDraft(tip: Money(300)).total(Cart.empty), const Money.zero());
    });

    test('"Otro" tiene tope', () {
      expect(const CheckoutDraft().copyWith(tip: const Money(99900)).tip, maxTip);
      expect(const CheckoutDraft(tip: Money(200)).copyWith(paymentKind: PaymentKind.card).tip, const Money(200));
    });

    test('el efectivo debe cubrir también la propina y calcula el vuelto', () {
      // total = 2800 + propina 300 = 3100
      const justBag = CheckoutDraft(paymentKind: PaymentKind.cash, cashChangeFor: Money(3000), tip: Money(300));
      expect(justBag.issues(cart, address), [CheckoutIssue.cashTooLow]);
      const fifty = CheckoutDraft(paymentKind: PaymentKind.cash, cashChangeFor: Money(5000), tip: Money(300));
      expect(fifty.issues(cart, address), isEmpty);
      expect(fifty.change(cart), const Money(1900));
    });
  });

  test('la nota para el negocio viaja en el pedido', () {
    final request = const CheckoutDraft(paymentKind: PaymentKind.yape).toRequest(cart.setNote(' tocar el timbre '), address);
    expect(request.notes, 'tocar el timbre');
  });

  group('horarios programables', () {
    final now = DateTime(2026, 9, 23, 12, 10);

    test('la primera hora es 45 min después, redondeada a 15', () {
      expect(firstSchedulable(now), DateTime(2026, 9, 23, 13));
      expect(firstSchedulable(DateTime(2026, 9, 23, 12, 15)), DateTime(2026, 9, 23, 13));
      expect(firstSchedulable(DateTime(2026, 9, 23, 12, 16)), DateTime(2026, 9, 23, 13, 15));
    });

    test('respeta la apertura del negocio (notBefore)', () {
      final opens = DateTime(2026, 9, 23, 18);
      expect(firstSchedulable(now, notBefore: opens), opens);
      final slots = scheduleSlots(now, notBefore: opens);
      expect(slots.first, ScheduleSlot(DateTime(2026, 9, 23, 17, 30), available: false));
      expect(slots[2], ScheduleSlot(opens, available: true));
    });

    test('cada 15 min, con las anteriores tachadas', () {
      final slots = scheduleSlots(now, count: 6);
      expect(slots.map((s) => s.at), [
        for (var i = 0; i < 6; i++) DateTime(2026, 9, 23, 12, 30).add(Duration(minutes: 15 * i)),
      ]);
      expect(slots.where((s) => !s.available).length, 2);
    });

    test('no pasa de medianoche y mañana empieza temprano', () {
      final late = DateTime(2026, 9, 23, 23, 40);
      expect(scheduleSlots(late).where((s) => s.available), isEmpty);
      final tomorrow = scheduleSlots(late, day: DateTime(2026, 9, 24));
      expect(tomorrow.first, ScheduleSlot(DateTime(2026, 9, 24, 7), available: true));
    });

    test('un día antes de la apertura queda todo tachado', () {
      final slots = scheduleSlots(now, notBefore: DateTime(2026, 9, 24, 9));
      expect(slots, isNotEmpty);
      expect(slots.every((s) => !s.available), isTrue);
    });
  });
}
