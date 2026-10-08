import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/notifications/domain/notice.dart';

/// Avisos de prueba en memoria (aún no hay endpoint `/notifications`). Las
/// fechas son relativas a "ahora" para que siempre haya HOY, AYER y ANTES.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this._backend, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final FakeBackend _backend;
  final DateTime Function() _clock;
  List<Notice>? _notices;

  List<Notice> _seed() {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    // Si es muy temprano, los avisos "de hoy" no pueden quedar en el futuro.
    DateTime todayAt(int hour, int minute, Duration fallback) {
      final at = today.add(Duration(hours: hour, minutes: minute));
      return at.isAfter(now) ? now.subtract(fallback) : at;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    return [
      Notice(
        id: 'nt_courier_near',
        kind: NoticeKind.courierNearby,
        title: 'Luis está a la vuelta 👀',
        body: 'Tu pedido de Doña Rosa llega en 2 min',
        at: now.subtract(const Duration(minutes: 3)),
      ),
      Notice(
        id: 'nt_courier_assigned',
        kind: NoticeKind.courierAssigned,
        title: 'Luis va por tu pedido',
        body: 'Reparte en Yauri desde 2019 · moto',
        at: now.subtract(const Duration(minutes: 14)),
      ),
      Notice(
        id: 'nt_preparing',
        kind: NoticeKind.preparing,
        title: '¡Rosa ya está cocinando!',
        body: 'Picantería Doña Rosa está preparando tu caldo',
        at: now.subtract(const Duration(minutes: 22)),
        read: true,
      ),
      Notice(
        id: 'nt_confirmed',
        kind: NoticeKind.orderConfirmed,
        title: 'Pedido confirmado',
        body: 'Doña Rosa recibió tu pedido #2481',
        at: now.subtract(const Duration(minutes: 25)),
        read: true,
      ),
      Notice(
        id: 'nt_promo_jugos',
        kind: NoticeKind.promotion,
        title: '2x1 en café de altura hasta las 5',
        body: 'Dulce Kantu · solo hoy',
        at: todayAt(11, 0, const Duration(hours: 1)),
        storeId: 'st_dulce_kantu',
      ),
      Notice(
        id: 'nt_delivered_botica',
        kind: NoticeKind.delivered,
        title: 'Entregado',
        body: 'Botica Salud Espinar · ¿qué tal estuvo?',
        at: yesterday.add(const Duration(hours: 19, minutes: 40)),
        storeId: 'st_botica_salud',
        read: true,
      ),
      Notice(
        id: 'nt_promo_pollo',
        kind: NoticeKind.promotion,
        title: 'Martes de 2x1 en pollo',
        body: 'El Chaski Dorado · de 11 am a 11 pm',
        at: yesterday.add(const Duration(hours: 10, minutes: 15)),
        storeId: 'st_chaski_dorado',
        read: true,
      ),
      Notice(
        id: 'nt_delivered_kantu',
        kind: NoticeKind.delivered,
        title: 'Entregado',
        body: 'Dulce Kantu · tu torta de chocolate llegó',
        at: today.subtract(const Duration(days: 4, hours: 7)),
        storeId: 'st_dulce_kantu',
        read: true,
      ),
    ];
  }

  /// Como `GET /notifications/feed`: hilo del pedido en curso, resto por día.
  @override
  Future<Result<NoticeFeed>> feed(NoticeFilter filter) => guard(() async {
    await _backend.delay();
    final all = _notices ??= _seed();
    final thread = filter == NoticeFilter.offers ? const <Notice>[] : _activeOrderThread(all);
    final inThread = {for (final n in thread) n.id};
    bool accepts(Notice n) => switch (filter) {
      NoticeFilter.all => true,
      NoticeFilter.orders => n.kind.isOrder,
      NoticeFilter.offers => !n.kind.isOrder,
    };
    final rest = all.where((n) => !inThread.contains(n.id) && accepts(n)).toList()..sort((a, b) => b.at.compareTo(a.at));
    final now = _clock();
    NoticeDay dayOf(DateTime at) =>
        switch (DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays) {
          <= 0 => NoticeDay.today,
          1 => NoticeDay.yesterday,
          _ => NoticeDay.earlier,
        };
    final groups = <NoticeGroup>[];
    for (final n in rest) {
      final day = dayOf(n.at);
      if (groups.lastOrNull?.day == day) {
        groups.last.items.add(n);
      } else {
        groups.add(NoticeGroup(day: day, items: [n]));
      }
    }
    return NoticeFeed(thread: thread, groups: groups, unreadCount: all.where((n) => !n.read).length, total: all.length);
  });

  /// Avisos del pedido en curso (antiguo → reciente); vacío si hay menos de dos.
  static List<Notice> _activeOrderThread(List<Notice> notices) {
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
    final thread = latest.sublist(latest.lastIndexWhere((n) => n.kind.closesOrder) + 1);
    return thread.length < 2 ? const [] : thread;
  }

  @override
  Future<Result<void>> markAllRead() => guard(() async {
    await _backend.delay();
    _notices = [for (final n in _notices ??= _seed()) n.markRead()];
  });
}
