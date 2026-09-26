import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:equatable/equatable.dart';

/// Pedido visto por un socio (negocio o repartidor): el pedido del cliente más
/// a quién, dónde recogerlo y dónde entregarlo. Nunca se muestra al cliente.
final class StaffOrder extends Equatable {
  const StaffOrder({
    required this.order,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryLocation,
    required this.pickup,
    required this.distanceMeters,
    this.cancelReason,
    this.collection,
  });

  final Order order;
  final String customerName;
  final String customerPhone;
  final GeoCoordinates deliveryLocation;
  final Pickup pickup;
  final int distanceMeters;
  final String? cancelReason;

  /// Lo que cobró el repartidor al entregar.
  final Collection? collection;

  String get id => order.id;

  OrderStatus get status => order.status;

  @override
  List<Object?> get props => [
    order, customerName, customerPhone, deliveryLocation, pickup, distanceMeters, cancelReason, collection,
  ];
}

/// Nombre corto del estado para los socios.
extension StaffStatusLabel on OrderStatus {
  String get staffLabel => switch (this) {
    OrderStatus.received => 'Nuevo',
    OrderStatus.confirmed => 'Aceptado',
    OrderStatus.preparing => 'Preparando',
    OrderStatus.ready => 'Listo para recoger',
    OrderStatus.courierAssigned => 'Repartidor en camino al local',
    OrderStatus.onTheWay => 'En camino al cliente',
    OrderStatus.delivered => 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
  };
}

/// Dónde recoger el pedido: los datos actuales del negocio.
final class Pickup extends Equatable {
  const Pickup({required this.address, required this.location, this.phone});

  final String address;
  final String? phone;
  final GeoCoordinates location;

  @override
  List<Object?> get props => [address, phone, location];
}

/// Medios con los que se cobra contraentrega.
enum CollectionMethod {
  cash('Efectivo'),
  yape('Yape'),
  plin('Plin');

  const CollectionMethod(this.label);

  final String label;

  /// El que eligió el cliente al pedir (tarjeta no se acepta contraentrega).
  static CollectionMethod from(PaymentMethod payment) => switch (payment) {
    YapePayment() => yape,
    PlinPayment() => plin,
    CashPayment() || CardPayment() => cash,
  };
}

final class Collection extends Equatable {
  const Collection({required this.method, required this.amount, required this.at});

  final CollectionMethod method;
  final Money amount;
  final DateTime at;

  @override
  List<Object?> get props => [method, amount, at];
}
