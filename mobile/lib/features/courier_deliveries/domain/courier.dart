import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/orders/domain/staff_order.dart';
import 'package:equatable/equatable.dart';

/// Disponibilidad del repartidor. Con un pedido en curso está [busy].
enum CourierAvailability { offline, available, busy }

final class CourierProfile extends Equatable {
  const CourierProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleLabel,
    required this.availability,
    this.activeOrderId,
  });

  final String id;
  final String name;
  final String phone;

  /// "Moto roja": lo que ve el cliente.
  final String vehicleLabel;
  final CourierAvailability availability;

  /// El pedido que está llevando, si tiene uno.
  final String? activeOrderId;

  bool get isOnline => availability != CourierAvailability.offline;

  @override
  List<Object?> get props => [id, name, phone, vehicleLabel, availability, activeOrderId];
}

/// Cómo va el día del repartidor: para rendir cuentas del efectivo.
final class CourierSummary extends Equatable {
  const CourierSummary({
    required this.deliveredCount,
    required this.total,
    required this.cash,
    required this.yape,
    required this.plin,
  });

  final int deliveredCount;
  final Money total;
  final Money cash;
  final Money yape;
  final Money plin;

  @override
  List<Object?> get props => [deliveredCount, total, cash, yape, plin];
}

abstract interface class CourierRepository {
  Future<Result<CourierProfile>> me();

  /// Conectarse (recibir pedidos) o desconectarse.
  Future<Result<CourierProfile>> setOnline({required bool online});

  /// Pedidos listos para recoger en su ciudad (vacío si está desconectado).
  Future<Result<List<StaffOrder>>> available();

  Future<Result<List<StaffOrder>>> activeDeliveries();

  Future<Result<StaffOrder>> accept(String orderId);

  /// Ya lo recogió en el negocio: sale a entregarlo.
  Future<Result<StaffOrder>> pickedUp(String orderId);

  /// Entregado; registra cómo pagó el cliente y cuánto recibió.
  Future<Result<StaffOrder>> delivered(String orderId, {required CollectionMethod method, required Money amount});

  Future<Result<CourierSummary>> summary();
}
