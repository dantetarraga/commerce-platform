import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:equatable/equatable.dart';

/// Cuándo entregar.
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

/// Decisiones del checkout (lo demás sale de la bolsa).
///
/// La propina empieza en cero a propósito: es un regalo del cliente, no un
/// cargo preseleccionado (nada se suma al total sin que lo elijas).
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
  Money? change(Cart cart) {
    final paysWith = cashChangeFor;
    if (paymentKind != PaymentKind.cash || paysWith == null) return null;
    final diff = paysWith.cents - total(cart).cents;
    return diff >= 0 ? Money(diff) : null;
  }

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

  /// Validación completa antes de confirmar.
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

/// Minutos mínimos entre ahora y una entrega programada (preparar + llevar).
const scheduleLeadMinutes = 45;

/// Minutos que dura la ventana de llegada ("entre 6:30 y 6:50 pm").
const deliveryWindowMinutes = 20;

/// Una hora de la grilla "¿Para cuándo?".
final class ScheduleSlot extends Equatable {
  const ScheduleSlot(this.at, {required this.available});

  final DateTime at;

  /// `false` = ya pasó o el negocio aún no abre (se muestra tachada).
  final bool available;

  @override
  List<Object?> get props => [at, available];
}

DateTime _ceilTo15(DateTime t) {
  final base = DateTime(t.year, t.month, t.day, t.hour);
  final minutes = t.minute + (t.second > 0 || t.millisecond > 0 || t.microsecond > 0 ? 1 : 0);
  return base.add(Duration(minutes: ((minutes + 14) ~/ 15) * 15));
}

/// Primera hora programable: [scheduleLeadMinutes] desde ahora o [notBefore]
/// (p. ej. cuando abre un negocio cerrado), lo que sea después, redondeado a
/// los siguientes 15 min.
DateTime firstSchedulable(DateTime now, {DateTime? notBefore}) {
  final lead = now.add(const Duration(minutes: scheduleLeadMinutes));
  return _ceilTo15(notBefore != null && notBefore.isAfter(lead) ? notBefore : lead);
}

/// Grilla de horas de [day], cada 15 min: [past] horas previas tachadas como
/// contexto y luego hasta [count] en total, sin pasar de la medianoche. Los
/// días futuros empiezan a las [dayStartHour].
List<ScheduleSlot> scheduleSlots(
  DateTime now, {
  DateTime? day,
  DateTime? notBefore,
  int count = 12,
  int past = 2,
  int dayStartHour = 7,
}) {
  final date = day ?? now;
  final dayStart = DateTime(date.year, date.month, date.day, dayStartHour);
  final nextDay = DateTime(date.year, date.month, date.day + 1);
  final first = firstSchedulable(now, notBefore: notBefore);
  if (!first.isBefore(nextDay)) {
    // Ese día todavía no se puede: solo contexto tachado.
    return [for (var i = 0; i < count; i++) ScheduleSlot(dayStart.add(Duration(minutes: 15 * i)), available: false)];
  }
  final firstOfDay = first.isBefore(dayStart) ? dayStart : first;
  final context = firstOfDay.subtract(Duration(minutes: 15 * past));
  final start = context.isBefore(dayStart) ? dayStart : context;
  return [
    for (var i = 0; i < count; i++) start.add(Duration(minutes: 15 * i)),
  ].where((t) => t.isBefore(nextDay)).map((t) => ScheduleSlot(t, available: !t.isBefore(firstOfDay))).toList();
}
