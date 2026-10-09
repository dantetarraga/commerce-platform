import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/addresses/addresses_domain.dart';
import 'package:apamuy/features/cart/cart_domain.dart';
import 'package:apamuy/features/orders/orders_domain.dart';
import 'package:equatable/equatable.dart';

sealed class DeliveryTime extends Equatable {
  const DeliveryTime();

  @override
  List<Object?> get props => [];
}

final class DeliverAsap extends DeliveryTime {
  const DeliverAsap();
}

final class DeliverAt extends DeliveryTime {
  const DeliverAt(this.at);

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

enum PaymentKind {
  yape,
  plin,
  cash,
  card;

  /// Lo que se ofrece hoy: todo contraentrega, y sin tarjeta porque los
  /// repartidores no llevan POS (ver docs/OPERACION.md §4).
  static const List<PaymentKind> offered = [yape, plin, cash];
}

/// Lo que falta para poder confirmar, en el orden en que se muestra.
enum CheckoutIssue { emptyCart, belowMinimum, missingAddress, missingPayment, cashTooLow }

/// Montos rápidos de propina (en céntimos): S/ 1 · 2 · 3.
const List<Money> tipPresets = [Money(100), Money(200), Money(300)];

/// Tope de la propina "Otro" (S/ 50): evita errores de tipeo.
const Money maxTip = Money(5000);

/// Billetes con los que se suele pagar en efectivo (S/ 20 · 50 · 100 · 200).
const List<Money> cashBills = [Money(2000), Money(5000), Money(10000), Money(20000)];

/// Sugerencias de "¿Con cuánto pagas?": hasta [max] billetes mayores que
/// [total], de menor a mayor.
List<Money> suggestedBills(Money total, {int max = 3}) => [
  for (final bill in cashBills)
    if (total < bill) bill,
].take(max).toList();

/// Vuelto al pagar [total] con [paysWith]: `null` si paga exacto (sin monto)
/// o si no alcanza.
Money? cashChange(Money? paysWith, Money total) =>
    paysWith == null || paysWith < total ? null : paysWith - total;

/// Decisiones del checkout (lo demás sale de la bolsa). La propina empieza en
/// cero a propósito: nada se suma al total sin que lo elijas.
final class CheckoutDraft extends Equatable {
  const CheckoutDraft({
    this.deliveryTime = const DeliverAsap(),
    this.paymentKind,
    this.cashChangeFor,
    this.tip = const Money.zero(),
  });

  final DeliveryTime deliveryTime;
  final PaymentKind? paymentKind;

  /// Con cuánto paga en efectivo (null = monto exacto).
  final Money? cashChangeFor;

  /// Propina para el repartidor (100 % para quien lo lleva).
  final Money tip;

  PaymentMethod? get payment => switch (paymentKind) {
    PaymentKind.yape => const YapePayment(),
    PaymentKind.plin => const PlinPayment(),
    PaymentKind.card => const CardPayment(),
    PaymentKind.cash => CashPayment(changeFor: cashChangeFor),
    null => null,
  };

  /// Total a pagar: la bolsa más la propina.
  Money total(Cart cart) => cart.isEmpty ? const Money.zero() : cart.total + tip;

  /// Vuelto que lleva el repartidor (null si paga exacto o no alcanza).
  Money? change(Cart cart) => paymentKind == PaymentKind.cash ? cashChange(cashChangeFor, total(cart)) : null;

  List<Money> bills(Cart cart) => suggestedBills(total(cart));

  CheckoutDraft copyWith({
    DeliveryTime? deliveryTime,
    PaymentKind? paymentKind,
    Money? cashChangeFor,
    bool clearChange = false,
    Money? tip,
  }) => CheckoutDraft(
    deliveryTime: deliveryTime ?? this.deliveryTime,
    paymentKind: paymentKind ?? this.paymentKind,
    cashChangeFor: clearChange ? null : (cashChangeFor ?? this.cashChangeFor),
    tip: tip == null ? this.tip : (maxTip < tip ? maxTip : tip),
  );

  List<CheckoutIssue> issues(Cart cart, Address? address) => [
    if (cart.isEmpty) CheckoutIssue.emptyCart,
    if (!cart.isEmpty && !cart.reachesMinimum) CheckoutIssue.belowMinimum,
    if (address == null) CheckoutIssue.missingAddress,
    if (paymentKind == null) CheckoutIssue.missingPayment,
    if (paymentKind == PaymentKind.cash && cashChangeFor != null && cashChangeFor! < total(cart)) CheckoutIssue.cashTooLow,
  ];

  /// Arma el pedido a enviar. Solo llamar si [issues] está vacío.
  PlaceOrderRequest toRequest(Cart cart, Address address) => PlaceOrderRequest(
    storeId: cart.store!.id,
    items: [
      for (final line in cart.lines)
        PlaceOrderItem(
          productId: line.productId,
          variantId: line.variantId,
          optionValueIds: [for (final c in line.choices) c.valueId],
          quantity: line.quantity.value,
          notes: line.notes,
        ),
    ],
    addressTitle: address.title,
    addressStreet: address.street,
    addressReference: address.reference,
    latitude: address.coordinates.latitude,
    longitude: address.coordinates.longitude,
    payment: payment!,
    couponCode: cart.coupon?.code,
    scheduledFor: switch (deliveryTime) {
      DeliverAt(:final at) => at,
      DeliverAsap() => null,
    },
    tip: tip,
    notes: cart.note,
  );

  @override
  List<Object?> get props => [deliveryTime, paymentKind, cashChangeFor, tip];
}

extension CheckoutIssueMessage on CheckoutIssue {
  String get message => switch (this) {
    CheckoutIssue.emptyCart => 'Tu bolsa está vacía.',
    CheckoutIssue.belowMinimum => 'Aún no llegas al pedido mínimo del negocio.',
    CheckoutIssue.missingAddress => 'Elige dónde te lo llevamos.',
    CheckoutIssue.missingPayment => 'Elige cómo pagas.',
    CheckoutIssue.cashTooLow => 'El efectivo no alcanza para el total.',
  };
}

/// Minutos que dura la ventana de llegada ("entre 6:30 y 6:50 pm").
const deliveryWindowMinutes = 20;
