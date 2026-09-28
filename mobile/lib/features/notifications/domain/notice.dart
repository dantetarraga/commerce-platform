import 'package:chaski/core/result/result.dart';
import 'package:equatable/equatable.dart';

/// Tipo de aviso: los del pedido siguen su recorrido; la promo va aparte.
enum NoticeKind {
  orderConfirmed,
  preparing,
  courierAssigned,
  courierNearby,
  delivered,
  orderCancelled,
  promotion;

  /// Avisos del pedido (terracota suave; las promos, en hierba).
  bool get isOrder => this != promotion;

  /// El pedido terminó: ya no hay nada que seguir.
  bool get closesOrder => this == delivered || this == orderCancelled;
}

/// Un aviso del centro de avisos (la campana de Cerca).
final class Notice extends Equatable {
  const Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    this.orderId,
    this.storeId,
  });

  final String id;
  final NoticeKind kind;

  /// "Luis está a la vuelta 👀".
  final String title;

  /// "Tu pedido de Doña Rosa llega en 2 min".
  final String body;
  final DateTime at;
  final bool read;

  /// A dónde lleva al tocarlo: el seguimiento del pedido o el negocio.
  final String? orderId;
  final String? storeId;

  Notice markRead() => read
      ? this
      : Notice(id: id, kind: kind, title: title, body: body, at: at, read: true, orderId: orderId, storeId: storeId);

  @override
  List<Object?> get props => [id, kind, title, body, at, read, orderId, storeId];
}

/// Grupo de la lista: HOY, AYER o ANTES.
enum NoticeDay {
  today,
  yesterday,
  earlier;

  static NoticeDay of(DateTime at, DateTime now) {
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;
    return switch (days) {
      <= 0 => today,
      1 => yesterday,
      _ => earlier,
    };
  }

  String get label => switch (this) {
    today => 'HOY',
    yesterday => 'AYER',
    earlier => 'ANTES',
  };
}

/// Agrupa los avisos (más reciente primero) por día, sin grupos vacíos.
Map<NoticeDay, List<Notice>> groupNotices(List<Notice> notices, DateTime now) {
  final sorted = [...notices]..sort((a, b) => b.at.compareTo(a.at));
  final groups = <NoticeDay, List<Notice>>{};
  for (final n in sorted) {
    (groups[NoticeDay.of(n.at, now)] ??= []).add(n);
  }
  return {for (final day in NoticeDay.values) day: ?groups[day]};
}

/// Avisos del pedido que sigue en camino, del más antiguo al más reciente, para
/// mostrarlos juntos como un solo hilo. Vacío si no hay pedido en curso o si
/// tiene un único aviso (entonces se muestra como uno más). Los avisos sin
/// [Notice.orderId] (los de prueba) cuentan como el mismo pedido.
List<Notice> activeOrderThread(List<Notice> notices) {
  final byOrder = <String?, List<Notice>>{};
  for (final n in notices.where((n) => n.kind.isOrder)) {
    (byOrder[n.orderId] ??= []).add(n);
  }
  List<Notice>? latest;
  for (final group in byOrder.values) {
    group.sort((a, b) => a.at.compareTo(b.at));
    if (group.last.kind.closesOrder) continue;
    if (latest == null || group.last.at.isAfter(latest.last.at)) latest = group;
  }
  if (latest == null || latest.length < 2) return const [];
  // Solo el tramo desde el último cierre (un pedido anterior sin orderId).
  final start = latest.lastIndexWhere((n) => n.kind.closesOrder) + 1;
  final thread = latest.sublist(start);
  return thread.length < 2 ? const [] : thread;
}

abstract interface class NotificationsRepository {
  Future<Result<List<Notice>>> list();

  Future<Result<void>> markAllRead();
}
