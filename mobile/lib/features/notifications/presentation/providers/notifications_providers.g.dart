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

/// El centro de avisos de una pestaña, armado por el backend. Se guarda por
/// pestaña: volver a una ya vista es instantáneo.

@ProviderFor(noticeFeed)
final noticeFeedProvider = NoticeFeedFamily._();

/// El centro de avisos de una pestaña, armado por el backend. Se guarda por
/// pestaña: volver a una ya vista es instantáneo.

final class NoticeFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<NoticeFeed>,
          NoticeFeed,
          FutureOr<NoticeFeed>
        >
    with $FutureModifier<NoticeFeed>, $FutureProvider<NoticeFeed> {
  /// El centro de avisos de una pestaña, armado por el backend. Se guarda por
  /// pestaña: volver a una ya vista es instantáneo.
  NoticeFeedProvider._({
    required NoticeFeedFamily super.from,
    required NoticeFilter super.argument,
  }) : super(
         retry: null,
         name: r'noticeFeedProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noticeFeedHash();

  @override
  String toString() {
    return r'noticeFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NoticeFeed> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<NoticeFeed> create(Ref ref) {
    final argument = this.argument as NoticeFilter;
    return noticeFeed(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoticeFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noticeFeedHash() => r'cf644315798b4ea5927a9fda8de7cf64705946ff';

/// El centro de avisos de una pestaña, armado por el backend. Se guarda por
/// pestaña: volver a una ya vista es instantáneo.

final class NoticeFeedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NoticeFeed>, NoticeFilter> {
  NoticeFeedFamily._()
    : super(
        retry: null,
        name: r'noticeFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// El centro de avisos de una pestaña, armado por el backend. Se guarda por
  /// pestaña: volver a una ya vista es instantáneo.

  NoticeFeedProvider call(NoticeFilter filter) =>
      NoticeFeedProvider._(argument: filter, from: this);

  @override
  String toString() => r'noticeFeedProvider';
}

/// "Marcar leídos". Al terminar vuelve a pedir el centro de avisos.

@ProviderFor(NoticeActions)
final noticeActionsProvider = NoticeActionsProvider._();

/// "Marcar leídos". Al terminar vuelve a pedir el centro de avisos.
final class NoticeActionsProvider
    extends $NotifierProvider<NoticeActions, void> {
  /// "Marcar leídos". Al terminar vuelve a pedir el centro de avisos.
  NoticeActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeActionsHash();

  @$internal
  @override
  NoticeActions create() => NoticeActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$noticeActionsHash() => r'97cc6fee9a3824c8b5c03e148e2a5c204e6da564';

/// "Marcar leídos". Al terminar vuelve a pedir el centro de avisos.

abstract class _$NoticeActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Avisos sin leer (el punto de la campana en Cerca), según el backend.

@ProviderFor(unreadNoticesCount)
final unreadNoticesCountProvider = UnreadNoticesCountProvider._();

/// Avisos sin leer (el punto de la campana en Cerca), según el backend.

final class UnreadNoticesCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Avisos sin leer (el punto de la campana en Cerca), según el backend.
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
    r'113677449cac417db3e04dc0c187d77597ae2eaa';

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
