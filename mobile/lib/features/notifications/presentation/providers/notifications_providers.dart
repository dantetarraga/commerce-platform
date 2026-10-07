import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/infrastructure/api_notifications_repository.dart';
import 'package:chaski/features/notifications/infrastructure/fake_notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers escritos a mano (sin codegen).

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => ref.watch(appEnvProvider).useFakeData
      ? FakeNotificationsRepository(ref.watch(fakeBackendProvider))
      : ApiNotificationsRepository(ref.watch(apiClientProvider)),
);

/// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".
final notificationsProvider = AsyncNotifierProvider<NotificationsController, List<Notice>>(NotificationsController.new);

class NotificationsController extends AsyncNotifier<List<Notice>> {
  @override
  Future<List<Notice>> build() async {
    final notices = (await ref.watch(notificationsRepositoryProvider).list()).getOrThrow();
    return [...notices]..sort((a, b) => b.at.compareTo(a.at));
  }

  /// Optimista: la lista cambia al instante; si falla, vuelve a la anterior.
  Future<void> markAllRead() async {
    final previous = state.value;
    if (previous == null || previous.every((n) => n.read)) return;
    state = AsyncData([for (final n in previous) n.markRead()]);
    final result = await ref.read(notificationsRepositoryProvider).markAllRead();
    if (!result.isOk && ref.mounted) state = AsyncData(previous);
  }
}

/// Avisos sin leer (el punto lima de la campana en Cerca).
final unreadNoticesCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0,
);
