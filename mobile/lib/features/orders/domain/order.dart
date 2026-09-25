import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/result/result.dart';
import 'package:equatable/equatable.dart';

/// Estados del pedido en orden. `cancelled` puede ocurrir antes de `onTheWay`.
enum OrderStatus {
  received,
  confirmed,
  preparing,
  ready,
  courierAssigned,
  onTheWay,
  delivered,
  cancelled;

  bool get isFinal => this == delivered || this == cancelled;

  /// Pasos visibles en el seguimiento (sin `cancelled`).
  static const List<OrderStatus> timeline = [received, confirmed, preparing, ready, courierAssigned, onTheWay, delivered];
}

sealed class PaymentMethod extends Equatable {
  const PaymentMethod();

  String get label;

  @override
  List<Object?> get props => [label];
}

final class YapePayment extends PaymentMethod {
  const YapePayment();

  @override
  String get label => 'Yape';
}

final class PlinPayment extends PaymentMethod {
  const PlinPayment();

  @override
  String get label => 'Plin';
}

/// Efectivo; [changeFor] = con cuánto paga (para llevar el vuelto).
final class CashPayment extends PaymentMethod {
  const CashPayment({this.changeFor});

  final Money? changeFor;

  @override
  String get label => 'Efectivo';

  @override
  List<Object?> get props => [label, changeFor];
}

final class CardPayment extends PaymentMethod {
  const CardPayment();

  @override
  String get label => 'Tarjeta al recibir';
}

final class OrderLine extends Equatable {
  const OrderLine({required this.name, required this.quantity, required this.total, this.description = '', this.productId});

  final String? productId;
  final String name;
  final int quantity;
  final Money total;
  final String description;

  @override
  List<Object?> get props => [productId, name, quantity, total, description];
}

final class OrderStore extends Equatable {
  const OrderStore({required this.id, required this.name, this.logoUrl, this.ownerName});

  final String id;
  final String name;
  final String? logoUrl;

  /// "Rosa": quien prepara el pedido (los mensajes la nombran).
  final String? ownerName;

  @override
  List<Object?> get props => [id, name, logoUrl, ownerName];
}

final class Courier extends Equatable {
  const Courier({required this.name, required this.vehicle, this.since, this.avatarUrl});

  final String name;
  final String vehicle;

  /// Año desde el que reparte en la ciudad.
  final int? since;
  final String? avatarUrl;

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [name, vehicle, since, avatarUrl];
}

final class OrderEvent extends Equatable {
  const OrderEvent(this.status, this.at);

  final OrderStatus status;
  final DateTime at;

  @override
  List<Object?> get props => [status, at];
}

final class Order extends Equatable {
  const Order({
    required this.id,
    required this.code,
    required this.store,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.addressTitle,
    required this.addressStreet,
    required this.payment,
    required this.status,
    required this.events,
    required this.placedAt,
    this.addressReference = '',
    this.courier,
    this.estimatedArrival,
    this.scheduledFor,
    this.rating,
    this.tip = const Money.zero(),
  });

  final String id;

  /// Código corto para hablar con el negocio: "#2481".
  final String code;
  final OrderStore store;
  final List<OrderLine> lines;
  final Money subtotal;
  final Money deliveryFee;
  final Money discount;

  /// Propina para el repartidor (100 % para quien lo lleva). Ya va en [total].
  final Money tip;
  final Money total;
  final String addressTitle;
  final String addressStreet;
  final String addressReference;
  final PaymentMethod payment;
  final OrderStatus status;
  final List<OrderEvent> events;
  final DateTime placedAt;
  final Courier? courier;
  final DateTime? estimatedArrival;

  /// Entrega programada (null = lo antes posible).
  final DateTime? scheduledFor;

  /// 1..5 estrellas si ya se calificó.
  final int? rating;

  bool get isActive => !status.isFinal;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  DateTime? timeOf(OrderStatus s) => events.where((e) => e.status == s).firstOrNull?.at;

  bool reached(OrderStatus s) =>
      status != OrderStatus.cancelled && OrderStatus.timeline.indexOf(status) >= OrderStatus.timeline.indexOf(s);

  /// Minutos que faltan para la llegada estimada (mínimo 1 mientras esté activo).
  int? minutesLeft(DateTime now) {
    final eta = estimatedArrival;
    if (eta == null || !isActive) return null;
    final m = eta.difference(now).inMinutes;
    return m < 1 ? 1 : m;
  }

  /// Mensaje humano del estado, con nombres propios.
  String get headline {
    final owner = store.ownerName ?? store.name;
    final rider = courier?.firstName ?? 'Tu repartidor';
    return switch (status) {
      OrderStatus.received => 'Recibimos tu pedido',
      OrderStatus.confirmed => '$owner confirmó tu pedido',
      OrderStatus.preparing => '$owner está preparando tu pedido',
      OrderStatus.ready => 'Tu pedido está listo',
      OrderStatus.courierAssigned => '$rider va por tu pedido',
      OrderStatus.onTheWay => '$rider va en camino',
      OrderStatus.delivered => 'Entregado. ¡Buen provecho!',
      OrderStatus.cancelled => 'Pedido cancelado',
    };
  }

  /// Línea de apoyo bajo el título.
  String get detail => switch (status) {
    OrderStatus.received => 'Esperando que ${store.name} lo acepte.',
    OrderStatus.confirmed => 'En unos minutos empieza a prepararse.',
    OrderStatus.preparing => 'Te avisamos apenas esté listo.',
    OrderStatus.ready => 'Buscando a alguien de la zona para llevarlo.',
    OrderStatus.courierAssigned => 'Está recogiendo tu pedido en ${store.name}.',
    OrderStatus.onTheWay => 'Ten a mano ${payment is CashPayment ? 'el efectivo' : 'tu celular'}.',
    OrderStatus.delivered => '¿Qué tal estuvo?',
    OrderStatus.cancelled => 'No se te cobró nada.',
  };

  Order copyWith({int? rating}) => Order(
    id: id,
    code: code,
    store: store,
    lines: lines,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    total: total,
    addressTitle: addressTitle,
    addressStreet: addressStreet,
    addressReference: addressReference,
    payment: payment,
    status: status,
    events: events,
    placedAt: placedAt,
    courier: courier,
    estimatedArrival: estimatedArrival,
    scheduledFor: scheduledFor,
    rating: rating ?? this.rating,
    tip: tip,
  );

  @override
  List<Object?> get props => [
    id, code, store, lines, subtotal, deliveryFee, discount, total, addressTitle, addressStreet,
    addressReference, payment, status, events, placedAt, courier, estimatedArrival, scheduledFor, rating, tip,
  ];
}

/// Lo que se envía al confirmar. El backend recalcula precios y totales.
final class PlaceOrderRequest extends Equatable {
  const PlaceOrderRequest({
    required this.storeId,
    required this.items,
    required this.addressTitle,
    required this.addressStreet,
    required this.latitude,
    required this.longitude,
    required this.payment,
    this.addressReference = '',
    this.couponCode,
    this.scheduledFor,
    this.tip = const Money.zero(),
    this.notes = '',
  });

  final String storeId;
  final List<PlaceOrderItem> items;
  final String addressTitle;
  final String addressStreet;
  final String addressReference;
  final double latitude;
  final double longitude;
  final PaymentMethod payment;
  final String? couponCode;
  final DateTime? scheduledFor;

  /// Propina para el repartidor; el backend la suma al total.
  final Money tip;

  /// Nota general para el negocio ("tocar el timbre dos veces").
  final String notes;

  @override
  List<Object?> get props => [
    storeId, items, addressTitle, addressStreet, addressReference, latitude, longitude, payment, couponCode, scheduledFor,
    tip, notes,
  ];
}

final class PlaceOrderItem extends Equatable {
  const PlaceOrderItem({
    required this.productId,
    required this.quantity,
    this.variantId,
    this.optionValueIds = const [],
    this.notes = '',
  });

  final String productId;
  final String? variantId;
  final List<String> optionValueIds;
  final int quantity;
  final String notes;

  @override
  List<Object?> get props => [productId, variantId, optionValueIds, quantity, notes];
}

abstract interface class OrdersRepository {
  /// [idempotencyKey]: repetir la llamada con la misma clave (doble tap,
  /// reintento tras un corte) devuelve el mismo pedido en vez de crear otro.
  Future<Result<Order>> placeOrder(PlaceOrderRequest request, {String? idempotencyKey});

  /// Estado vivo del pedido: emite el actual y cada cambio.
  Stream<Order> watch(String orderId);

  Future<Result<Order>> getOrder(String orderId);

  Future<Result<List<Order>>> history();

  Future<Result<Order>> rate(String orderId, {required int rating, String comment = ''});
}
