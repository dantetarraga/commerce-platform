// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(merchantRemoteDataSource)
final merchantRemoteDataSourceProvider = MerchantRemoteDataSourceProvider._();

final class MerchantRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          MerchantRemoteDataSource,
          MerchantRemoteDataSource,
          MerchantRemoteDataSource
        >
    with $Provider<MerchantRemoteDataSource> {
  MerchantRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<MerchantRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantRemoteDataSource create(Ref ref) {
    return merchantRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantRemoteDataSource>(value),
    );
  }
}

String _$merchantRemoteDataSourceHash() =>
    r'2e4cf94d85454356ab4af19f8f6a6bd5f745c03d';

@ProviderFor(merchantRepository)
final merchantRepositoryProvider = MerchantRepositoryProvider._();

final class MerchantRepositoryProvider
    extends
        $FunctionalProvider<
          MerchantRepository,
          MerchantRepository,
          MerchantRepository
        >
    with $Provider<MerchantRepository> {
  MerchantRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantRepositoryHash();

  @$internal
  @override
  $ProviderElement<MerchantRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantRepository create(Ref ref) {
    return merchantRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantRepository>(value),
    );
  }
}

String _$merchantRepositoryHash() =>
    r'6eb711edb0f367685e76ef7e9a9c4879b630c629';

/// Negocios del socio. Pausar o reanudar es optimista.

@ProviderFor(MerchantStores)
final merchantStoresProvider = MerchantStoresProvider._();

/// Negocios del socio. Pausar o reanudar es optimista.
final class MerchantStoresProvider
    extends $AsyncNotifierProvider<MerchantStores, List<MerchantStore>> {
  /// Negocios del socio. Pausar o reanudar es optimista.
  MerchantStoresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantStoresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantStoresHash();

  @$internal
  @override
  MerchantStores create() => MerchantStores();
}

String _$merchantStoresHash() => r'aa1b20342f7e2d64adf8f5db09abf5bd1a242e63';

/// Negocios del socio. Pausar o reanudar es optimista.

abstract class _$MerchantStores extends $AsyncNotifier<List<MerchantStore>> {
  FutureOr<List<MerchantStore>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MerchantStore>>, List<MerchantStore>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MerchantStore>>, List<MerchantStore>>,
              AsyncValue<List<MerchantStore>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Pedidos en curso. Llegan al instante con `store.orders.changed` (también
/// el pedido nuevo); sin WebSocket, se consultan cada [merchantPollEvery].

@ProviderFor(merchantActiveOrders)
final merchantActiveOrdersProvider = MerchantActiveOrdersProvider._();

/// Pedidos en curso. Llegan al instante con `store.orders.changed` (también
/// el pedido nuevo); sin WebSocket, se consultan cada [merchantPollEvery].

final class MerchantActiveOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffOrder>>,
          List<StaffOrder>,
          FutureOr<List<StaffOrder>>
        >
    with $FutureModifier<List<StaffOrder>>, $FutureProvider<List<StaffOrder>> {
  /// Pedidos en curso. Llegan al instante con `store.orders.changed` (también
  /// el pedido nuevo); sin WebSocket, se consultan cada [merchantPollEvery].
  MerchantActiveOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantActiveOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantActiveOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<StaffOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StaffOrder>> create(Ref ref) {
    return merchantActiveOrders(ref);
  }
}

String _$merchantActiveOrdersHash() =>
    r'567f9d6632e88e23dc83da775e058174d16871c2';

/// Los pedidos en curso repartidos en las tres columnas del riel.

@ProviderFor(merchantBoard)
final merchantBoardProvider = MerchantBoardProvider._();

/// Los pedidos en curso repartidos en las tres columnas del riel.

final class MerchantBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>,
          AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>,
          AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>
        >
    with $Provider<AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>> {
  /// Los pedidos en curso repartidos en las tres columnas del riel.
  MerchantBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantBoardHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>> create(Ref ref) {
    return merchantBoard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>>
          >(value),
    );
  }
}

String _$merchantBoardHash() => r'0e47f4422eac4997f8f20a612ded8cce6e4291c0';

@ProviderFor(merchantTodayOrders)
final merchantTodayOrdersProvider = MerchantTodayOrdersProvider._();

final class MerchantTodayOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffOrder>>,
          List<StaffOrder>,
          FutureOr<List<StaffOrder>>
        >
    with $FutureModifier<List<StaffOrder>>, $FutureProvider<List<StaffOrder>> {
  MerchantTodayOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantTodayOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantTodayOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<StaffOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StaffOrder>> create(Ref ref) {
    return merchantTodayOrders(ref);
  }
}

String _$merchantTodayOrdersHash() =>
    r'24a033c461dde8ee21c9c245c2a63edeeb9993c4';

@ProviderFor(merchantSummary)
final merchantSummaryProvider = MerchantSummaryProvider._();

final class MerchantSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<MerchantSummary>,
          MerchantSummary,
          FutureOr<MerchantSummary>
        >
    with $FutureModifier<MerchantSummary>, $FutureProvider<MerchantSummary> {
  MerchantSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantSummaryHash();

  @$internal
  @override
  $FutureProviderElement<MerchantSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MerchantSummary> create(Ref ref) {
    return merchantSummary(ref);
  }
}

String _$merchantSummaryHash() => r'4b180be3c93202ecf07e17fef7cf5905a1696a7f';

/// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

@ProviderFor(MerchantOrderActions)
final merchantOrderActionsProvider = MerchantOrderActionsProvider._();

/// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
final class MerchantOrderActionsProvider
    extends $NotifierProvider<MerchantOrderActions, void> {
  /// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
  // keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
  MerchantOrderActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantOrderActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantOrderActionsHash();

  @$internal
  @override
  MerchantOrderActions create() => MerchantOrderActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$merchantOrderActionsHash() =>
    r'ed9d7f58ed78a77b8a032b137e66284960ce20b3';

/// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

abstract class _$MerchantOrderActions extends $Notifier<void> {
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

/// La carta de un negocio para una pestaña y una búsqueda. El backend filtra,
/// busca, agrupa y cuenta; cada cambio de pestaña o búsqueda es una consulta.

@ProviderFor(merchantCatalog)
final merchantCatalogProvider = MerchantCatalogFamily._();

/// La carta de un negocio para una pestaña y una búsqueda. El backend filtra,
/// busca, agrupa y cuenta; cada cambio de pestaña o búsqueda es una consulta.

final class MerchantCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<MerchantCatalog>,
          MerchantCatalog,
          FutureOr<MerchantCatalog>
        >
    with $FutureModifier<MerchantCatalog>, $FutureProvider<MerchantCatalog> {
  /// La carta de un negocio para una pestaña y una búsqueda. El backend filtra,
  /// busca, agrupa y cuenta; cada cambio de pestaña o búsqueda es una consulta.
  MerchantCatalogProvider._({
    required MerchantCatalogFamily super.from,
    required (String, {ProductFilter filter, String query}) super.argument,
  }) : super(
         retry: null,
         name: r'merchantCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$merchantCatalogHash();

  @override
  String toString() {
    return r'merchantCatalogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MerchantCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MerchantCatalog> create(Ref ref) {
    final argument =
        this.argument as (String, {ProductFilter filter, String query});
    return merchantCatalog(
      ref,
      argument.$1,
      filter: argument.filter,
      query: argument.query,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MerchantCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$merchantCatalogHash() => r'd0a0673ab04495cb8eb1fb287e51f835458b7e35';

/// La carta de un negocio para una pestaña y una búsqueda. El backend filtra,
/// busca, agrupa y cuenta; cada cambio de pestaña o búsqueda es una consulta.

final class MerchantCatalogFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MerchantCatalog>,
          (String, {ProductFilter filter, String query})
        > {
  MerchantCatalogFamily._()
    : super(
        retry: null,
        name: r'merchantCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// La carta de un negocio para una pestaña y una búsqueda. El backend filtra,
  /// busca, agrupa y cuenta; cada cambio de pestaña o búsqueda es una consulta.

  MerchantCatalogProvider call(
    String storeId, {
    ProductFilter filter = ProductFilter.all,
    String query = '',
  }) => MerchantCatalogProvider._(
    argument: (storeId, filter: filter, query: query),
    from: this,
  );

  @override
  String toString() => r'merchantCatalogProvider';
}

/// Marcar un producto disponible o agotado. Al terminar vuelve a pedir la
/// carta (en "Disponibles" el producto agotado ya no viene).
// keepAlive: si se liberara a mitad del cambio, se perdería el refresco.

@ProviderFor(MerchantProductActions)
final merchantProductActionsProvider = MerchantProductActionsProvider._();

/// Marcar un producto disponible o agotado. Al terminar vuelve a pedir la
/// carta (en "Disponibles" el producto agotado ya no viene).
// keepAlive: si se liberara a mitad del cambio, se perdería el refresco.
final class MerchantProductActionsProvider
    extends $NotifierProvider<MerchantProductActions, void> {
  /// Marcar un producto disponible o agotado. Al terminar vuelve a pedir la
  /// carta (en "Disponibles" el producto agotado ya no viene).
  // keepAlive: si se liberara a mitad del cambio, se perdería el refresco.
  MerchantProductActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantProductActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantProductActionsHash();

  @$internal
  @override
  MerchantProductActions create() => MerchantProductActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$merchantProductActionsHash() =>
    r'5557ce8ea8dec43f2c1f71eef259669a086acb8b';

/// Marcar un producto disponible o agotado. Al terminar vuelve a pedir la
/// carta (en "Disponibles" el producto agotado ya no viene).
// keepAlive: si se liberara a mitad del cambio, se perdería el refresco.

abstract class _$MerchantProductActions extends $Notifier<void> {
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
