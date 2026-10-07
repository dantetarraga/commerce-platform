import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/infrastructure/api_notifications_repository.dart';
import 'package:chaski/features/notifications/infrastructure/fake_notifications_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeNotificationsRepository(ref.watch(fakeBackendProvider))
    : ApiNotificationsRepository(ref.watch(apiClientProvider));

/// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".
@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  Future<List<Notice>> build() async {
    final notices = (await ref.watch(notificationsRepositoryProvider).list()).getOrThrow();
    return [...notices]..sort((a, b) => b.at.compareTo(a.at));
  }

  /// Optimista: la lista cambia al instante; si falla, vuelve a la anterior y
  /// devuelve el error para avisarlo.
  Future<Failure?> markAllRead() async {
    final previous = state.value;
    if (previous == null || previous.every((n) => n.read)) return null;
    state = AsyncData([for (final n in previous) n.markRead()]);
    final result = await ref.read(notificationsRepositoryProvider).markAllRead();
    switch (result) {
      case Ok():
        return null;
      case Err(:final failure):
        if (ref.mounted) state = AsyncData(previous);
        return failure;
    }
  }
}

/// Avisos sin leer (el punto de la campana en Cerca).
@riverpod
int unreadNoticesCount(Ref ref) => ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0;

enum NoticeFilter {
  all('Todos'),
  orders('Pedidos'),
  offers('Ofertas');

  const NoticeFilter(this.label);

  final String label;

  bool accepts(Notice n) => switch (this) {
    all => true,
    orders => n.kind.isOrder,
    offers => !n.kind.isOrder,
  };
}

@riverpod
class NoticeFilterSelection extends _$NoticeFilterSelection {
  @override
  NoticeFilter build() => NoticeFilter.all;

  void select(NoticeFilter filter) => state = filter;
}

/// Lo que muestra el centro de avisos con el filtro elegido: el hilo del pedido
/// en curso (si hay) y el resto agrupado por día.
typedef NoticeFeed = ({List<Notice> thread, Map<NoticeDay, List<Notice>> groups});

@riverpod
AsyncValue<NoticeFeed> noticeFeed(Ref ref) {
  final filter = ref.watch(noticeFilterSelectionProvider);
  return ref.watch(notificationsProvider).whenData((list) {
    final thread = filter == NoticeFilter.offers ? const <Notice>[] : activeOrderThread(list);
    final inThread = {for (final n in thread) n.id};
    final rest = list.where((n) => !inThread.contains(n.id) && filter.accepts(n)).toList();
    return (thread: thread, groups: groupNotices(rest, DateTime.now()));
  });
}
