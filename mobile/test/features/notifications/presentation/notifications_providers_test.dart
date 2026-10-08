import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsRepository extends Mock implements NotificationsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [fakeBackendProvider.overrideWithValue(FakeBackend(latency: Duration.zero))]);
    addTearDown(c.dispose);
    return c;
  }

  test('los no leídos vienen del backend y "Marcar leídos" los deja en cero', () async {
    final c = container()..listen(unreadNoticesCountProvider, (_, _) {});
    await c.read(noticeFeedProvider(NoticeFilter.all).future);
    expect(c.read(unreadNoticesCountProvider), greaterThan(0));

    expect(await c.read(noticeActionsProvider.notifier).markAllRead(), isNull);
    await c.read(noticeFeedProvider(NoticeFilter.all).future);
    expect(c.read(unreadNoticesCountProvider), 0);
  });

  test('si "Marcar leídos" falla, devuelve el error y el conteo sigue igual', () async {
    final repository = _MockNotificationsRepository();
    final promo = Notice(id: 'n1', kind: NoticeKind.promotion, title: 'Promo', body: '2x1', at: DateTime(2026, 9, 22));
    when(() => repository.feed(NoticeFilter.all)).thenAnswer(
      (_) async => Ok(NoticeFeed(thread: const [], groups: [NoticeGroup(day: NoticeDay.earlier, items: [promo])], unreadCount: 1, total: 1)),
    );
    when(repository.markAllRead).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = ProviderContainer(overrides: [notificationsRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(c.dispose);
    c.listen(unreadNoticesCountProvider, (_, _) {});
    await c.read(noticeFeedProvider(NoticeFilter.all).future);

    final failure = await c.read(noticeActionsProvider.notifier).markAllRead();
    expect(failure, isA<NetworkFailure>());
    await c.read(noticeFeedProvider(NoticeFilter.all).future);
    expect(c.read(unreadNoticesCountProvider), 1);
  });

  test('cada pestaña pide su propio feed', () async {
    final c = container();
    final all = await c.read(noticeFeedProvider(NoticeFilter.all).future);
    final offers = await c.read(noticeFeedProvider(NoticeFilter.offers).future);
    expect(all.thread, isNotEmpty);
    expect(offers.thread, isEmpty);
    expect(offers.groups.expand((g) => g.items).every((n) => !n.kind.isOrder), isTrue);
  });
}
