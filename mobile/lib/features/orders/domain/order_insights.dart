import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/orders/domain/order.dart';

/// Datos derivados de un pedido.
extension OrderInsights on Order {
  /// "2481": el código sin el "#", para leerlo en voz alta o compararlo.
  String get shortCode => code.startsWith('#') ? code.substring(1) : code;

  /// Lo que vale el pedido sin el envío (lo que se le paga al negocio).
  Money get itemsSubtotal => deliveryFee < total ? total - deliveryFee : Money.zero(currency: total.currency);

  /// Vuelto que debe llevar el repartidor: con cuánto paga menos el total.
  /// `null` si no paga en efectivo, paga exacto o el monto no alcanza.
  Money? get changeDue {
    final paysWith = switch (payment) {
      CashPayment(:final changeFor) => changeFor,
      _ => null,
    };
    if (paysWith == null || paysWith < total) return null;
    return paysWith - total;
  }

  /// Cuándo el repartidor salió con el pedido (lo recogió en el negocio).
  DateTime? get pickedUpAt => timeOf(OrderStatus.onTheWay);

  /// Avance estimado del repartidor (0 a 1) entre la salida y la llegada estimada.
  /// No es GPS: en camino se mueve entre 0.05 y 0.95 para que siempre se vea.
  double routeProgress(DateTime now) {
    if (status == OrderStatus.delivered) return 1;
    if (!reached(OrderStatus.onTheWay)) return 0;
    final left = pickedUpAt;
    final eta = estimatedArrival;
    if (left == null || eta == null) return 0.05;
    final total = eta.difference(left).inSeconds;
    if (total <= 0) return 0.9;
    return (now.difference(left).inSeconds / total).clamp(0.05, 0.95);
  }

  /// Paso de la portada del pedido activo (0 a 3): confirmado · preparando ·
  /// en camino · llegando. "Llegando" son los últimos 3 minutos en camino.
  int activeStep(DateTime now) => switch (status) {
    OrderStatus.received || OrderStatus.confirmed => 0,
    OrderStatus.preparing || OrderStatus.ready => 1,
    OrderStatus.courierAssigned => 2,
    OrderStatus.onTheWay => (minutesLeft(now) ?? 99) <= 3 ? 3 : 2,
    OrderStatus.delivered || OrderStatus.cancelled => 3,
  };
}
