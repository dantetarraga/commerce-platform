import 'package:chaski/features/orders/domain/order.dart';

/// Etiquetas de estado de un pedido para la UI, en un solo lugar. Las usan el
/// seguimiento, la lista de pedidos, la ayuda, la portada del inicio y las
/// pantallas de los socios.
extension OrderStatusLabels on OrderStatus {
  /// Etiqueta viva en mayúsculas: "EN CAMINO".
  String get tag => switch (this) {
    OrderStatus.received => 'RECIBIDO',
    OrderStatus.confirmed => 'CONFIRMADO',
    OrderStatus.preparing => 'PREPARANDO',
    OrderStatus.ready => 'LISTO',
    OrderStatus.courierAssigned => 'RECOGIENDO',
    OrderStatus.onTheWay => 'EN CAMINO',
    OrderStatus.delivered => 'ENTREGADO',
    OrderStatus.cancelled => 'CANCELADO',
  };

  /// Nombre corto para el cliente: "Listo para salir", "En camino".
  String get label => switch (this) {
    OrderStatus.received => 'Recibido',
    OrderStatus.confirmed => 'Confirmado',
    OrderStatus.preparing => 'Preparando',
    OrderStatus.ready => 'Listo para salir',
    OrderStatus.courierAssigned => 'Repartidor asignado',
    OrderStatus.onTheWay => 'En camino',
    OrderStatus.delivered => 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
  };

  /// Resumen para listas e historial: "Entregado", "Cancelado" o "En curso".
  String get summaryLabel => switch (this) {
    OrderStatus.delivered => 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
    _ => 'En curso',
  };

  /// Nombre corto del estado para los socios ("Nuevo", "Listo para recoger").
  String get partnerLabel => switch (this) {
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

/// Títulos de la línea de tiempo del seguimiento, con nombres propios.
extension OrderStepTitles on Order {
  /// "Confirmado por Rosa" · "Rosa lo está preparando" · "Luis va en camino".
  String stepTitle(OrderStatus step) {
    final owner = store.ownerName ?? store.name;
    final rider = courier?.firstName;
    return switch (step) {
      OrderStatus.received => 'Recibido',
      OrderStatus.confirmed => 'Confirmado por $owner',
      OrderStatus.preparing => reached(OrderStatus.ready) ? 'Preparado por $owner' : '$owner lo está preparando',
      OrderStatus.ready => 'Listo para salir',
      OrderStatus.courierAssigned => rider == null ? 'Repartidor asignado' : '$rider va a recogerlo',
      OrderStatus.onTheWay => rider == null ? 'En camino' : '$rider va en camino',
      OrderStatus.delivered => 'Entregado',
      OrderStatus.cancelled => 'Cancelado',
    };
  }
}

/// Los cuatro pasos de la portada del pedido activo, por índice de
/// `Order.activeStep`.
const activeStepLabels = ['Confirmado', 'Preparando', 'En camino', 'Llegando'];
