import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 23, 14);

  Notice notice(String id, DateTime at, {NoticeKind kind = NoticeKind.delivered}) =>
      Notice(id: id, kind: kind, title: 't', body: 'b', at: at);

  test('agrupa por HOY, AYER y ANTES, lo más reciente primero y sin grupos vacíos', () {
    final groups = groupNotices([
      notice('viejo', DateTime(2026, 9, 18, 9)),
      notice('hoy-temprano', DateTime(2026, 9, 23, 8)),
      notice('hoy', DateTime(2026, 9, 23, 13)),
      notice('antes-2', DateTime(2026, 9, 21, 9)),
    ], now);

    expect(groups.keys, [NoticeDay.today, NoticeDay.earlier]);
    expect(groups[NoticeDay.today]!.map((n) => n.id), ['hoy', 'hoy-temprano']);
    expect(groups[NoticeDay.earlier]!.map((n) => n.id), ['antes-2', 'viejo']);
    expect(NoticeDay.of(DateTime(2026, 9, 22, 23, 59), now), NoticeDay.yesterday);
    expect(NoticeDay.yesterday.label, 'AYER');
  });

  test('marcar leído conserva el resto y las promos no son de pedido', () {
    final n = notice('a', now, kind: NoticeKind.promotion);
    expect(n.read, isFalse);
    expect(n.markRead(), isA<Notice>().having((x) => x.read, 'read', isTrue).having((x) => x.id, 'id', 'a'));
    expect(NoticeKind.promotion.isOrder, isFalse);
    expect(NoticeKind.courierNearby.isOrder, isTrue);
  });

  group('activeOrderThread', () {
    final now = DateTime(2026, 9, 27, 13);
    Notice n(String id, NoticeKind kind, int minutesAgo, {String? orderId}) =>
        Notice(id: id, kind: kind, title: id, body: '', at: now.subtract(Duration(minutes: minutesAgo)), orderId: orderId);

    test('junta los avisos del pedido en curso, del más antiguo al más reciente', () {
      final thread = activeOrderThread([
        n('near', NoticeKind.courierNearby, 3),
        n('promo', NoticeKind.promotion, 5),
        n('confirmed', NoticeKind.orderConfirmed, 25),
        n('old_delivered', NoticeKind.delivered, 60 * 20),
        n('old_confirmed', NoticeKind.orderConfirmed, 60 * 21),
      ]);
      expect(thread.map((e) => e.id), ['confirmed', 'near']);
    });

    test('un pedido entregado o con un solo aviso no forma hilo', () {
      expect(activeOrderThread([n('a', NoticeKind.orderConfirmed, 10), n('b', NoticeKind.delivered, 2)]), isEmpty);
      expect(activeOrderThread([n('a', NoticeKind.preparing, 10)]), isEmpty);
    });

    test('elige el pedido con el aviso más reciente', () {
      final thread = activeOrderThread([
        n('a1', NoticeKind.orderConfirmed, 50, orderId: 'a'),
        n('a2', NoticeKind.preparing, 40, orderId: 'a'),
        n('b1', NoticeKind.orderConfirmed, 9, orderId: 'b'),
        n('b2', NoticeKind.courierAssigned, 4, orderId: 'b'),
      ]);
      expect(thread.map((e) => e.id), ['b1', 'b2']);
    });
  });
}
