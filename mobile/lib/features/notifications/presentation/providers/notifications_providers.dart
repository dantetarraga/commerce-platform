import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/notifications/domain/notice.dart';
import 'package:apamuy/features/notifications/infrastructure/api_notifications_repository.dart';
import 'package:apamuy/features/notifications/infrastructure/fake_notifications_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeNotificationsRepository(ref.watch(fakeBackendProvider))
    : ApiNotificationsRepository(ref.watch(apiClientProvider));

/// El centro de avisos de una pestaña, armado por el backend. Se guarda por
/// pestaña: volver a una ya vista es instantáneo.
@Riverpod(keepAlive: true)
Future<NoticeFeed> noticeFeed(Ref ref, NoticeFilter filter) =>
    ref.watch(notificationsRepositoryProvider).feed(filter).then((r) => r.getOrThrow());

/// "Marcar leídos". Al terminar vuelve a pedir el centro de avisos.
@Riverpod(keepAlive: true)
class NoticeActions extends _$NoticeActions {
  @override
  void build() {}

  Future<Failure?> markAllRead() async {
    final result = await ref.read(notificationsRepositoryProvider).markAllRead();
    if (!ref.mounted) return null;
    ref.invalidate(noticeFeedProvider);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}

/// Avisos sin leer (el punto de la campana en Cerca), según el backend.
@riverpod
int unreadNoticesCount(Ref ref) => ref.watch(noticeFeedProvider(NoticeFilter.all)).value?.unreadCount ?? 0;

@riverpod
class NoticeFilterSelection extends _$NoticeFilterSelection {
  @override
  NoticeFilter build() => NoticeFilter.all;

  void select(NoticeFilter filter) => state = filter;
}
