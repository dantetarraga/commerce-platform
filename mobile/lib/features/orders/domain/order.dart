import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/orders/domain/payment_method.dart';
import 'package:equatable/equatable.dart';
export 'payment_method.dart';

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

  /// Etapa para la barra de avance de la lista de pedidos (0 a [stageCount] − 1).
  int get stage => switch (this) {
    received => 0,
    confirmed => 1,
    preparing || ready => 2,
    courierAssigned || onTheWay => 3,
    delivered || cancelled => 4,
  };

  /// Cantidad de etapas de [stage].
  static const stageCount = 5;
}

final class OrderLine extends Equatable {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.total,
    this.description = '',
    this.productId,
    this.notes = '',
  });

  final String? productId;
  final String name;
  final int quantity;
  final Money total;
  final String description;

  /// Nota del cliente para este producto ("sin ají"). Solo la ven los socios.
  final String notes;

  @override
  List<Object?> get props => [productId, name, quantity, total, description, notes];
}

final class OrderStore extends Equatable {
  const OrderStore({required this.id, required this.name, this.logoUrl, this.ownerName, this.location});

  final String id;
  final String name;
  final String? logoUrl;

  /// "Rosa": quien prepara el pedido (los mensajes la nombran).
  final String? ownerName;

  /// Dónde está el negocio (para el mapa del seguimiento).
  final GeoCoordinates? location;

  @override
  List<Object?> get props => [id, name, logoUrl, ownerName, location];
}

final class Courier extends Equatable {
  const Courier({required this.name, required this.vehicle, this.since, this.avatarUrl, this.position});

  final String name;
  final String vehicle;

  /// Año desde el que reparte en la ciudad.
  final int? since;
  final String? avatarUrl;

  /// Dónde va, solo mientras lleva el pedido y si la posición es reciente.
  final CourierPosition? position;

  Courier withPosition(CourierPosition? position) =>
      Courier(name: name, vehicle: vehicle, since: since, avatarUrl: avatarUrl, position: position);

  String get firstName => name.split(' ').first;

  /// "LQ" para el avatar: iniciales de las dos primeras palabras del nombre.
  String get initials => name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  @override
  List<Object?> get props => [name, vehicle, since, avatarUrl, position];
}

final class CourierPosition extends Equatable {
  const CourierPosition(this.coordinates, this.at);

  final GeoCoordinates coordinates;
  final DateTime at;

  @override
  List<Object?> get props => [coordinates, at];
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
    this.destination,
    this.courier,
    this.estimatedArrival,
    this.scheduledFor,
    this.rating,
    this.tip = const Money.zero(),
    this.notes = '',
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

  /// El punto de entrega (para el mapa del seguimiento).
  final GeoCoordinates? destination;
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

  /// Nota general del cliente ("tocar el timbre dos veces").
  final String notes;

  bool get isActive => !status.isFinal;

  /// El cliente puede cancelar mientras el negocio no empezó a prepararlo
  /// (misma regla que el backend).
  bool get canBeCancelled => status == OrderStatus.received || status == OrderStatus.confirmed;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  DateTime? timeOf(OrderStatus s) => events.where((e) => e.status == s).firstOrNull?.at;

  bool reached(OrderStatus s) =>
      status != OrderStatus.cancelled && OrderStatus.timeline.indexOf(status) >= OrderStatus.timeline.indexOf(s);

  /// Minutos que faltan para la llegada estimada (mínimo 1 mientras esté activo).
  /// `null` si falta más de [countdownMinutes] (un programado): ahí se muestra la hora.
  int? minutesLeft(DateTime now) {
    final eta = estimatedArrival;
    if (eta == null || !isActive) return null;
    final m = eta.difference(now).inMinutes;
    if (m > countdownMinutes) return null;
    return m < 1 ? 1 : m;
  }

  /// Hasta cuánto se cuenta en minutos; más lejos, "Llega a las 7:25 pm".
  static const countdownMinutes = 90;

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

  Order copyWith({int? rating, Courier? courier}) => Order(
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
    destination: destination,
    payment: payment,
    status: status,
    events: events,
    placedAt: placedAt,
    courier: courier ?? this.courier,
    estimatedArrival: estimatedArrival,
    scheduledFor: scheduledFor,
    rating: rating ?? this.rating,
    tip: tip,
    notes: notes,
  );

  @override
  List<Object?> get props => [
    id, code, store, lines, subtotal, deliveryFee, discount, total, addressTitle, addressStreet,
    addressReference, destination, payment, status, events, placedAt, courier, estimatedArrival, scheduledFor, rating, tip, notes,
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

/// Mis pedidos ya separados por el backend (`?scope=active|past`).
final class OrderLists extends Equatable {
  const OrderLists({required this.active, required this.past});

  static const empty = OrderLists(active: [], past: []);

  final List<Order> active;
  final List<Order> past;

  bool get isEmpty => active.isEmpty && past.isEmpty;

  @override
  List<Object?> get props => [active, past];
}

/// Un negocio de "Volver a pedir": su último pedido entregado y cuántos hubo.
final class RepeatEntry extends Equatable {
  const RepeatEntry({required this.order, required this.deliveredCount});

  final Order order;
  final int deliveredCount;

  @override
  List<Object?> get props => [order, deliveredCount];
}

/// Lo que el backend resume de los pedidos del cliente (`GET /orders/summary`).
final class OrdersSummary extends Equatable {
  const OrdersSummary({
    required this.orderCount,
    required this.activeCount,
    required this.saved,
    required this.repeat,
    this.latestOrderId,
  });

  static const empty = OrdersSummary(orderCount: 0, activeCount: 0, saved: Money.zero(), repeat: []);

  final int orderCount;
  final int activeCount;

  /// Lo ahorrado con cupones.
  final Money saved;
  final String? latestOrderId;
  final List<RepeatEntry> repeat;

  @override
  List<Object?> get props => [orderCount, activeCount, saved, latestOrderId, repeat];
}

abstract interface class OrdersRepository {
  /// [idempotencyKey]: repetir la llamada con la misma clave (doble tap,
  /// reintento tras un corte) devuelve el mismo pedido en vez de crear otro.
  Future<Result<Order>> placeOrder(PlaceOrderRequest request, {String? idempotencyKey});

  /// Estado vivo del pedido: emite el actual y cada cambio.
  Stream<Order> watch(String orderId);

  Future<Result<Order>> getOrder(String orderId);

  /// En curso y anteriores, cada lista pedida por separado al backend.
  Future<Result<OrderLists>> history();

  Future<Result<OrdersSummary>> summary();

  Future<Result<Order>> rate(String orderId, {required int rating, String comment = ''});

  Future<Result<Order>> cancel(String orderId, {String? reason});
}
