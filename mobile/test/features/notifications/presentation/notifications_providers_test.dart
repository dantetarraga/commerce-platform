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
  ProviderContainer container() {
    final c = ProviderContainer(overrides: [fakeBackendProvider.overrideWithValue(FakeBackend(latency: Duration.zero))]);
    addTearDown(c.dispose);
    return c;
  }

  test('cuenta los no leídos y "Marcar leídos" los deja en cero', () async {
    final c = container()..listen(unreadNoticesCountProvider, (_, _) {});
    final notices = await c.read(notificationsProvider.future);
    expect(notices, isNotEmpty);
    expect(c.read(unreadNoticesCountProvider), greaterThan(0));

    expect(await c.read(notificationsProvider.notifier).markAllRead(), isNull);
    expect(c.read(unreadNoticesCountProvider), 0);

    // El repositorio también quedó al día (sobrevive a recargar).
    c.invalidate(notificationsProvider);
    await c.read(notificationsProvider.future);
    expect(c.read(unreadNoticesCountProvider), 0);
  });

  test('si "Marcar leídos" falla, vuelve a la lista anterior y devuelve el error', () async {
    final repository = _MockNotificationsRepository();
    when(repository.list).thenAnswer(
      (_) async => Ok([Notice(id: 'n1', kind: NoticeKind.promotion, title: 'Promo', body: '2x1', at: DateTime(2026, 9, 22))]),
    );
    when(repository.markAllRead).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = ProviderContainer(overrides: [notificationsRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(c.dispose);
    c.listen(unreadNoticesCountProvider, (_, _) {});
    await c.read(notificationsProvider.future);

    final failure = await c.read(notificationsProvider.notifier).markAllRead();
    expect(failure, isA<NetworkFailure>());
    expect(c.read(unreadNoticesCountProvider), 1);
  });

  test('el filtro Ofertas deja fuera el hilo del pedido', () async {
    final c = container()..listen(noticeFeedProvider, (_, _) {});
    await c.read(notificationsProvider.future);
    expect(c.read(noticeFeedProvider).value!.thread, isNotEmpty);

    c.read(noticeFilterSelectionProvider.notifier).select(NoticeFilter.offers);
    final feed = c.read(noticeFeedProvider).value!;
    expect(feed.thread, isEmpty);
    expect(feed.groups.values.expand((g) => g).every((n) => !n.kind.isOrder), isTrue);
  });
}
