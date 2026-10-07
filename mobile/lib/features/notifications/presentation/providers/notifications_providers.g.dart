// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationsRepository)
final notificationsRepositoryProvider = NotificationsRepositoryProvider._();

final class NotificationsRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationsRepository,
          NotificationsRepository,
          NotificationsRepository
        >
    with $Provider<NotificationsRepository> {
  NotificationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsRepository create(Ref ref) {
    return notificationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsRepository>(value),
    );
  }
}

String _$notificationsRepositoryHash() =>
    r'525cb9cfb5bee84397ee2d62439c5d95e74afd62';

/// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".

@ProviderFor(Notifications)
final notificationsProvider = NotificationsProvider._();

/// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".
final class NotificationsProvider
    extends $AsyncNotifierProvider<Notifications, List<Notice>> {
  /// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  Notifications create() => Notifications();
}

String _$notificationsHash() => r'c5bedfe3beac95795c125183d37e524e0211f77f';

/// Avisos del usuario (más reciente primero) y la acción "Marcar leídos".

abstract class _$Notifications extends $AsyncNotifier<List<Notice>> {
  FutureOr<List<Notice>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Notice>>, List<Notice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Notice>>, List<Notice>>,
              AsyncValue<List<Notice>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Avisos sin leer (el punto de la campana en Cerca).

@ProviderFor(unreadNoticesCount)
final unreadNoticesCountProvider = UnreadNoticesCountProvider._();

/// Avisos sin leer (el punto de la campana en Cerca).

final class UnreadNoticesCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Avisos sin leer (el punto de la campana en Cerca).
  UnreadNoticesCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNoticesCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNoticesCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNoticesCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadNoticesCountHash() =>
    r'ec9fbdffe9c0ce660b8a61d12667b86d95e73bda';

@ProviderFor(NoticeFilterSelection)
final noticeFilterSelectionProvider = NoticeFilterSelectionProvider._();

final class NoticeFilterSelectionProvider
    extends $NotifierProvider<NoticeFilterSelection, NoticeFilter> {
  NoticeFilterSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeFilterSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeFilterSelectionHash();

  @$internal
  @override
  NoticeFilterSelection create() => NoticeFilterSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticeFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticeFilter>(value),
    );
  }
}

String _$noticeFilterSelectionHash() =>
    r'e8a59e332927e8ae6f22512fd459a4275ca72214';

abstract class _$NoticeFilterSelection extends $Notifier<NoticeFilter> {
  NoticeFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoticeFilter, NoticeFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoticeFilter, NoticeFilter>,
              NoticeFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(noticeFeed)
final noticeFeedProvider = NoticeFeedProvider._();

final class NoticeFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<NoticeFeed>,
          AsyncValue<NoticeFeed>,
          AsyncValue<NoticeFeed>
        >
    with $Provider<AsyncValue<NoticeFeed>> {
  NoticeFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeFeedHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<NoticeFeed>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<NoticeFeed> create(Ref ref) {
    return noticeFeed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<NoticeFeed> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<NoticeFeed>>(value),
    );
  }
}

String _$noticeFeedHash() => r'dee2a461dc1eba1806bcd83a70ce755505dc2fe8';
