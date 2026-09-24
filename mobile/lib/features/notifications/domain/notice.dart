import 'package:chaski/core/result/result.dart';
import 'package:equatable/equatable.dart';

/// Tipo de aviso: los del pedido siguen su recorrido; la promo va aparte.
enum NoticeKind {
  orderConfirmed,
  preparing,
  courierAssigned,
  courierNearby,
  delivered,
  promotion;

  /// Avisos del pedido (se pintan en cobalto suave; las promos, en lima).
  bool get isOrder => this != promotion;
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

abstract interface class NotificationsRepository {
  Future<Result<List<Notice>>> list();

  Future<Result<void>> markAllRead();
}
