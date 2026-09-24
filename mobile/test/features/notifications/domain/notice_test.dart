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
}
