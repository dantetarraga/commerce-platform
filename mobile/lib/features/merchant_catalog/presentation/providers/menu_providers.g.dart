// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fakeMerchantMenu)
final fakeMerchantMenuProvider = FakeMerchantMenuProvider._();

final class FakeMerchantMenuProvider
    extends
        $FunctionalProvider<
          FakeMerchantMenu,
          FakeMerchantMenu,
          FakeMerchantMenu
        >
    with $Provider<FakeMerchantMenu> {
  FakeMerchantMenuProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeMerchantMenuProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeMerchantMenuHash();

  @$internal
  @override
  $ProviderElement<FakeMerchantMenu> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeMerchantMenu create(Ref ref) {
    return fakeMerchantMenu(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeMerchantMenu value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeMerchantMenu>(value),
    );
  }
}

String _$fakeMerchantMenuHash() => r'b6c43293361bda5510eefcf9669a3d81d9067a95';

@ProviderFor(menuRemoteDataSource)
final menuRemoteDataSourceProvider = MenuRemoteDataSourceProvider._();

final class MenuRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          MenuRemoteDataSource,
          MenuRemoteDataSource,
          MenuRemoteDataSource
        >
    with $Provider<MenuRemoteDataSource> {
  MenuRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<MenuRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MenuRemoteDataSource create(Ref ref) {
    return menuRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuRemoteDataSource>(value),
    );
  }
}

String _$menuRemoteDataSourceHash() =>
    r'1880fc573ecd19a37704117fc0bbb4c43dbf83ff';

@ProviderFor(menuRepository)
final menuRepositoryProvider = MenuRepositoryProvider._();

final class MenuRepositoryProvider
    extends $FunctionalProvider<MenuRepository, MenuRepository, MenuRepository>
    with $Provider<MenuRepository> {
  MenuRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuRepositoryHash();

  @$internal
  @override
  $ProviderElement<MenuRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuRepository create(Ref ref) {
    return menuRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuRepository>(value),
    );
  }
}

String _$menuRepositoryHash() => r'56f099a8c00fe93559e12f63f9ad54b0a220b172';

/// Sube con cada cambio de la carta. La lista de productos de Socios la
/// escucha para volver a pedirse sin depender de este feature.

@ProviderFor(MenuRevision)
final menuRevisionProvider = MenuRevisionProvider._();

/// Sube con cada cambio de la carta. La lista de productos de Socios la
/// escucha para volver a pedirse sin depender de este feature.
final class MenuRevisionProvider extends $NotifierProvider<MenuRevision, int> {
  /// Sube con cada cambio de la carta. La lista de productos de Socios la
  /// escucha para volver a pedirse sin depender de este feature.
  MenuRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuRevisionHash();

  @$internal
  @override
  MenuRevision create() => MenuRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$menuRevisionHash() => r'd83c10f74f96e6aec2a0010d504325389b70d27c';

/// Sube con cada cambio de la carta. La lista de productos de Socios la
/// escucha para volver a pedirse sin depender de este feature.

abstract class _$MenuRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Lo que entró con la última importación, por nombre (como lo reconoce el
/// backend): la lista lo resalta hasta que el dueño lo da por visto.

@ProviderFor(ImportHighlights)
final importHighlightsProvider = ImportHighlightsProvider._();

/// Lo que entró con la última importación, por nombre (como lo reconoce el
/// backend): la lista lo resalta hasta que el dueño lo da por visto.
final class ImportHighlightsProvider
    extends $NotifierProvider<ImportHighlights, Map<String, ImportAction>> {
  /// Lo que entró con la última importación, por nombre (como lo reconoce el
  /// backend): la lista lo resalta hasta que el dueño lo da por visto.
  ImportHighlightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importHighlightsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importHighlightsHash();

  @$internal
  @override
  ImportHighlights create() => ImportHighlights();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ImportAction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ImportAction>>(value),
    );
  }
}

String _$importHighlightsHash() => r'4ce85fe9dd21502245974dc08297496b11bd0503';

/// Lo que entró con la última importación, por nombre (como lo reconoce el
/// backend): la lista lo resalta hasta que el dueño lo da por visto.

abstract class _$ImportHighlights extends $Notifier<Map<String, ImportAction>> {
  Map<String, ImportAction> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, ImportAction>, Map<String, ImportAction>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, ImportAction>, Map<String, ImportAction>>,
              Map<String, ImportAction>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// La carta editable de un negocio, con sus secciones.

@ProviderFor(storeMenu)
final storeMenuProvider = StoreMenuFamily._();

/// La carta editable de un negocio, con sus secciones.

final class StoreMenuProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoreMenu>,
          StoreMenu,
          FutureOr<StoreMenu>
        >
    with $FutureModifier<StoreMenu>, $FutureProvider<StoreMenu> {
  /// La carta editable de un negocio, con sus secciones.
  StoreMenuProvider._({
    required StoreMenuFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'storeMenuProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storeMenuHash();

  @override
  String toString() {
    return r'storeMenuProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StoreMenu> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StoreMenu> create(Ref ref) {
    final argument = this.argument as String;
    return storeMenu(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StoreMenuProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storeMenuHash() => r'6afc25ad043337d96bc48331d25a0ab413b4d5d9';

/// La carta editable de un negocio, con sus secciones.

final class StoreMenuFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StoreMenu>, String> {
  StoreMenuFamily._()
    : super(
        retry: null,
        name: r'storeMenuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// La carta editable de un negocio, con sus secciones.

  StoreMenuProvider call(String storeId) =>
      StoreMenuProvider._(argument: storeId, from: this);

  @override
  String toString() => r'storeMenuProvider';
}

/// Cambios a la carta. Cada uno devuelve la falla (o `null`) y, si salió bien,
/// refresca la carta y la lista de productos.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

@ProviderFor(MenuActions)
final menuActionsProvider = MenuActionsProvider._();

/// Cambios a la carta. Cada uno devuelve la falla (o `null`) y, si salió bien,
/// refresca la carta y la lista de productos.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
final class MenuActionsProvider extends $NotifierProvider<MenuActions, void> {
  /// Cambios a la carta. Cada uno devuelve la falla (o `null`) y, si salió bien,
  /// refresca la carta y la lista de productos.
  // keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
  MenuActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuActionsHash();

  @$internal
  @override
  MenuActions create() => MenuActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$menuActionsHash() => r'09499bee95cb2e546660df2f0260beec97a6e0be';

/// Cambios a la carta. Cada uno devuelve la falla (o `null`) y, si salió bien,
/// refresca la carta y la lista de productos.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

abstract class _$MenuActions extends $Notifier<void> {
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
