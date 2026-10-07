import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/domain/staff_order.dart';

/// Las tres columnas del riel de cocina del negocio.
enum MerchantBoardColumn {
  /// Comandas nuevas, esperando respuesta.
  fresh({OrderStatus.received}),

  /// En fogón: aceptadas y preparándose.
  cooking({OrderStatus.confirmed, OrderStatus.preparing}),

  /// Listas: esperando al repartidor o ya en camino.
  ready({OrderStatus.ready, OrderStatus.courierAssigned, OrderStatus.onTheWay});

  const MerchantBoardColumn(this.statuses);

  final Set<OrderStatus> statuses;

  /// Columna de un estado, o `null` si ya no está en el riel (entregado, cancelado).
  static MerchantBoardColumn? of(OrderStatus status) {
    for (final column in values) {
      if (column.statuses.contains(status)) return column;
    }
    return null;
  }

  /// Reparte [orders] en las tres columnas conservando su orden. Todas las
  /// columnas están en el mapa, aunque queden vacías.
  static Map<MerchantBoardColumn, List<StaffOrder>> group(Iterable<StaffOrder> orders) {
    final board = {for (final column in values) column: <StaffOrder>[]};
    for (final order in orders) {
      if (of(order.status) case final column?) board[column]!.add(order);
    }
    return board;
  }
}

/// Lo que el backend suma a la preparación para estimar la llegada al cliente.
const deliveryAllowance = Duration(minutes: 15);

/// Cómo va una comanda en el fogón: desde cuándo, para cuándo debe estar
/// lista y cuánto falta (o cuánto se pasó).
final class PrepProgress {
  const PrepProgress._({required this.startedAt, required this.readyBy, required this.now});

  /// Calcula el avance de [order] en [now]. Empieza al aceptarse (o al
  /// entrar, si no hay evento) y debe estar listo [deliveryAllowance] antes de
  /// la llegada estimada.
  factory PrepProgress.of(StaffOrder order, DateTime now) {
    final o = order.order;
    final started = o.events
            .where((e) => e.status == OrderStatus.confirmed || e.status == OrderStatus.preparing)
            .map((e) => e.at)
            .firstOrNull ??
        o.placedAt;
    final readyBy = o.estimatedArrival?.subtract(deliveryAllowance);
    return PrepProgress._(
      startedAt: started,
      readyBy: readyBy != null && readyBy.isAfter(started) ? readyBy : null,
      now: now,
    );
  }

  final DateTime startedAt;

  /// Hora prometida para tenerlo listo; `null` si no hay estimación útil.
  final DateTime? readyBy;
  final DateTime now;

  /// Avance de 0 a 1 hacia [readyBy]; `null` sin hora prometida.
  double? get fraction {
    final due = readyBy;
    if (due == null) return null;
    final total = due.difference(startedAt).inSeconds;
    return (now.difference(startedAt).inSeconds / total).clamp(0.0, 1.0);
  }

  /// Ya pasó la hora prometida.
  bool get isLate => readyBy != null && now.isAfter(readyBy!);

  /// Minutos que faltan (mínimo 1) o, si [isLate], los que se pasó. `null`
  /// sin hora prometida.
  int? get minutes {
    final due = readyBy;
    if (due == null) return null;
    final left = due.difference(now).inMinutes;
    return isLate ? -left : (left < 1 ? 1 : left);
  }

  /// "faltan 8 min" · "se pasó 3 min"; `null` sin hora prometida.
  String? get dueLabel => switch (minutes) {
    null => null,
    final m => isLate ? 'se pasó $m min' : 'faltan $m min',
  };
}

/// Bolsas que entrega el negocio: más de 3 productos no caben en una.
extension StaffOrderBags on StaffOrder {
  int get bagCount => order.itemCount > 3 ? 2 : 1;
}
