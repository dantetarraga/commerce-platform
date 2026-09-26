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

/// Pedidos en curso. Se refresca solo cada [merchantPollEvery].

@ProviderFor(merchantActiveOrders)
final merchantActiveOrdersProvider = MerchantActiveOrdersProvider._();

/// Pedidos en curso. Se refresca solo cada [merchantPollEvery].

final class MerchantActiveOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffOrder>>,
          List<StaffOrder>,
          FutureOr<List<StaffOrder>>
        >
    with $FutureModifier<List<StaffOrder>>, $FutureProvider<List<StaffOrder>> {
  /// Pedidos en curso. Se refresca solo cada [merchantPollEvery].
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
    r'2e8b0da3c95bf0079f5c95e3193e805cc3033ffa';

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
// keepAlive: se usa con `ref.read(...notifier)` y no debe liberarse a
// mitad de una acción (se perdería el refresco de las listas).

@ProviderFor(MerchantOrderActions)
final merchantOrderActionsProvider = MerchantOrderActionsProvider._();

/// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
// keepAlive: se usa con `ref.read(...notifier)` y no debe liberarse a
// mitad de una acción (se perdería el refresco de las listas).
final class MerchantOrderActionsProvider
    extends $NotifierProvider<MerchantOrderActions, void> {
  /// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
  // keepAlive: se usa con `ref.read(...notifier)` y no debe liberarse a
  // mitad de una acción (se perdería el refresco de las listas).
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
// keepAlive: se usa con `ref.read(...notifier)` y no debe liberarse a
// mitad de una acción (se perdería el refresco de las listas).

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

/// Productos de un negocio con su interruptor de disponible/agotado.

@ProviderFor(MerchantProducts)
final merchantProductsProvider = MerchantProductsFamily._();

/// Productos de un negocio con su interruptor de disponible/agotado.
final class MerchantProductsProvider
    extends $AsyncNotifierProvider<MerchantProducts, List<MerchantProduct>> {
  /// Productos de un negocio con su interruptor de disponible/agotado.
  MerchantProductsProvider._({
    required MerchantProductsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'merchantProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$merchantProductsHash();

  @override
  String toString() {
    return r'merchantProductsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MerchantProducts create() => MerchantProducts();

  @override
  bool operator ==(Object other) {
    return other is MerchantProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$merchantProductsHash() => r'ddff497f3bd1c82606634de38565c025cc14bf8d';

/// Productos de un negocio con su interruptor de disponible/agotado.

final class MerchantProductsFamily extends $Family
    with
        $ClassFamilyOverride<
          MerchantProducts,
          AsyncValue<List<MerchantProduct>>,
          List<MerchantProduct>,
          FutureOr<List<MerchantProduct>>,
          String
        > {
  MerchantProductsFamily._()
    : super(
        retry: null,
        name: r'merchantProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Productos de un negocio con su interruptor de disponible/agotado.

  MerchantProductsProvider call(String storeId) =>
      MerchantProductsProvider._(argument: storeId, from: this);

  @override
  String toString() => r'merchantProductsProvider';
}

/// Productos de un negocio con su interruptor de disponible/agotado.

abstract class _$MerchantProducts
    extends $AsyncNotifier<List<MerchantProduct>> {
  late final _$args = ref.$arg as String;
  String get storeId => _$args;

  FutureOr<List<MerchantProduct>> build(String storeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MerchantProduct>>, List<MerchantProduct>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MerchantProduct>>,
                List<MerchantProduct>
              >,
              AsyncValue<List<MerchantProduct>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
