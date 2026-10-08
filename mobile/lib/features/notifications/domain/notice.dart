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

/// Grupo de la lista: HOY, AYER o ANTES (lo decide el backend, en hora local).
enum NoticeDay {
  today,
  yesterday,
  earlier;

  String get label => switch (this) {
    today => 'HOY',
    yesterday => 'AYER',
    earlier => 'ANTES',
  };
}

/// Pestañas del centro de avisos.
enum NoticeFilter {
  all('Todos'),
  orders('Pedidos'),
  offers('Ofertas');

  const NoticeFilter(this.label);

  final String label;

  /// Nombre en la API (`?filter=`).
  String get apiName => name;
}

final class NoticeGroup extends Equatable {
  const NoticeGroup({required this.day, required this.items});

  final NoticeDay day;
  final List<Notice> items;

  @override
  List<Object?> get props => [day, items];
}

/// El centro de avisos armado por el backend para una pestaña: el hilo del
/// pedido en curso, el resto por día y cuántos hay sin leer.
final class NoticeFeed extends Equatable {
  const NoticeFeed({required this.thread, required this.groups, required this.unreadCount, required this.total});

  final List<Notice> thread;
  final List<NoticeGroup> groups;
  final int unreadCount;

  /// Avisos del usuario en total (sin filtro): 0 es "Todo tranquilo".
  final int total;

  @override
  List<Object?> get props => [thread, groups, unreadCount, total];
}

abstract interface class NotificationsRepository {
  Future<Result<NoticeFeed>> feed(NoticeFilter filter);

  Future<Result<void>> markAllRead();
}
