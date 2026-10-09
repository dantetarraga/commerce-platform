import 'package:apamuy/features/orders/orders_domain.dart';
import 'package:equatable/equatable.dart';

/// Las tres columnas del tablero del negocio. Qué pedido va en cuál lo
/// decide el backend (`GET /merchant/board`).
enum MerchantBoardColumn {
  /// Pedidos nuevos, esperando respuesta.
  fresh,

  /// Aceptados y en preparación.
  cooking,

  /// Listos: esperando al repartidor o ya en camino.
  ready,
}

/// Una columna del tablero: cuántos pedidos tiene y cuáles.
final class BoardColumn extends Equatable {
  const BoardColumn({required this.count, required this.items});

  static const empty = BoardColumn(count: 0, items: []);

  final int count;
  final List<StaffOrder> items;

  @override
  List<Object?> get props => [count, items];
}

/// El tablero tal como lo arma el backend.
final class MerchantBoard extends Equatable {
  const MerchantBoard(this.columns);

  final Map<MerchantBoardColumn, BoardColumn> columns;

  BoardColumn operator [](MerchantBoardColumn column) => columns[column] ?? BoardColumn.empty;

  @override
  List<Object?> get props => [columns];
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
