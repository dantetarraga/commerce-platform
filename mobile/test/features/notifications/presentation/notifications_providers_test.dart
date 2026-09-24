import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

    await c.read(notificationsProvider.notifier).markAllRead();
    expect(c.read(unreadNoticesCountProvider), 0);

    // El repositorio también quedó al día (sobrevive a recargar).
    c.invalidate(notificationsProvider);
    await c.read(notificationsProvider.future);
    expect(c.read(unreadNoticesCountProvider), 0);
  });
}
