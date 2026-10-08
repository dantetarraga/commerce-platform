import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/features/notifications/domain/notice.dart';
import 'package:apamuy/features/notifications/infrastructure/fake_notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marcar leído conserva el resto y las promos no son de pedido', () {
    final n = Notice(id: 'a', kind: NoticeKind.promotion, title: 't', body: 'b', at: DateTime(2026, 9, 23, 14));
    expect(n.read, isFalse);
    expect(n.markRead(), isA<Notice>().having((x) => x.read, 'read', isTrue).having((x) => x.id, 'id', 'a'));
    expect(NoticeKind.promotion.isOrder, isFalse);
    expect(NoticeKind.courierNearby.isOrder, isTrue);
    expect(NoticeDay.yesterday.label, 'AYER');
    expect(NoticeFilter.offers.apiName, 'offers');
  });

  // El fake hace de backend en la demo: arma el feed como `GET /notifications/feed`.
  test('el feed del fake trae el hilo en curso y el resto por día, sin repetir', () async {
    final repository = FakeNotificationsRepository(FakeBackend(latency: Duration.zero));
    final feed = (await repository.feed(NoticeFilter.all)).getOrThrow();
    final rest = feed.groups.expand((g) => g.items).toList();
    expect(feed.thread, isNotEmpty);
    expect(feed.groups.map((g) => g.day.index), [...feed.groups.map((g) => g.day.index)]..sort());
    expect(feed.total, feed.thread.length + rest.length);
    expect(feed.groups.map((g) => g.day.index), [...feed.groups.map((g) => g.day.index)]..sort());

    final offers = (await repository.feed(NoticeFilter.offers)).getOrThrow();
    expect(offers.thread, isEmpty);
    expect(offers.groups.expand((g) => g.items).every((n) => !n.kind.isOrder), isTrue);
  });
}
