// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stores_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storesRemoteDataSource)
final storesRemoteDataSourceProvider = StoresRemoteDataSourceProvider._();

final class StoresRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          StoresRemoteDataSource,
          StoresRemoteDataSource,
          StoresRemoteDataSource
        >
    with $Provider<StoresRemoteDataSource> {
  StoresRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storesRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<StoresRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StoresRemoteDataSource create(Ref ref) {
    return storesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoresRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoresRemoteDataSource>(value),
    );
  }
}

String _$storesRemoteDataSourceHash() =>
    r'45fe31e4ad73d5d1883c220a39cc82356ede8fac';

@ProviderFor(storesRepository)
final storesRepositoryProvider = StoresRepositoryProvider._();

final class StoresRepositoryProvider
    extends
        $FunctionalProvider<
          StoresRepository,
          StoresRepository,
          StoresRepository
        >
    with $Provider<StoresRepository> {
  StoresRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storesRepositoryHash();

  @$internal
  @override
  $ProviderElement<StoresRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StoresRepository create(Ref ref) {
    return storesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoresRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoresRepository>(value),
    );
  }
}

String _$storesRepositoryHash() => r'8106553331541cf69cf0231c36ef3e7cd0728c63';

/// Categorías con sus negocios abiertos en la ubicación de entrega actual.

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

/// Categorías con sus negocios abiertos en la ubicación de entrega actual.

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  /// Categorías con sus negocios abiertos en la ubicación de entrega actual.
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'c2dda05ea9fd1ac3f26ea83f15da8f5b7d782074';

/// Negocios para la ubicación de entrega actual.

@ProviderFor(stores)
final storesProvider = StoresFamily._();

/// Negocios para la ubicación de entrega actual.

final class StoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorePage>,
          StorePage,
          FutureOr<StorePage>
        >
    with $FutureModifier<StorePage>, $FutureProvider<StorePage> {
  /// Negocios para la ubicación de entrega actual.
  StoresProvider._({
    required StoresFamily super.from,
    required ({
      StoreSort sort,
      String? categoryId,
      StoreFilters filters,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'storesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storesHash();

  @override
  String toString() {
    return r'storesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<StorePage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StorePage> create(Ref ref) {
    final argument =
        this.argument
            as ({
              StoreSort sort,
              String? categoryId,
              StoreFilters filters,
              int limit,
            });
    return stores(
      ref,
      sort: argument.sort,
      categoryId: argument.categoryId,
      filters: argument.filters,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoresProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storesHash() => r'f924005495ded9e74a62ef0819901ff4ae14b4de';

/// Negocios para la ubicación de entrega actual.

final class StoresFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<StorePage>,
          ({
            StoreSort sort,
            String? categoryId,
            StoreFilters filters,
            int limit,
          })
        > {
  StoresFamily._()
    : super(
        retry: null,
        name: r'storesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Negocios para la ubicación de entrega actual.

  StoresProvider call({
    StoreSort sort = StoreSort.distance,
    String? categoryId,
    StoreFilters filters = StoreFilters.none,
    int limit = 20,
  }) => StoresProvider._(
    argument: (
      sort: sort,
      categoryId: categoryId,
      filters: filters,
      limit: limit,
    ),
    from: this,
  );

  @override
  String toString() => r'storesProvider';
}

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.
/// Consulta puntual de un negocio para otros features (repetir pedido, agregar rápido).

@ProviderFor(getStoreDetail)
final getStoreDetailProvider = GetStoreDetailProvider._();

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.
/// Consulta puntual de un negocio para otros features (repetir pedido, agregar rápido).

final class GetStoreDetailProvider
    extends $FunctionalProvider<GetStoreDetail, GetStoreDetail, GetStoreDetail>
    with $Provider<GetStoreDetail> {
  /// Distancia, delivery y ETA dependen de la ubicación de entrega actual.
  /// Consulta puntual de un negocio para otros features (repetir pedido, agregar rápido).
  GetStoreDetailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getStoreDetailProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getStoreDetailHash();

  @$internal
  @override
  $ProviderElement<GetStoreDetail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetStoreDetail create(Ref ref) {
    return getStoreDetail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetStoreDetail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetStoreDetail>(value),
    );
  }
}

String _$getStoreDetailHash() => r'1bf4d9708c0995f5a1ce34ee436efb695cbbc79b';

@ProviderFor(storeDetail)
final storeDetailProvider = StoreDetailFamily._();

final class StoreDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoreDetail>,
          StoreDetail,
          FutureOr<StoreDetail>
        >
    with $FutureModifier<StoreDetail>, $FutureProvider<StoreDetail> {
  StoreDetailProvider._({
    required StoreDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'storeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storeDetailHash();

  @override
  String toString() {
    return r'storeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StoreDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StoreDetail> create(Ref ref) {
    final argument = this.argument as String;
    return storeDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StoreDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storeDetailHash() => r'342e76536319b816d07c2e2f37154317dc66db9a';

final class StoreDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StoreDetail>, String> {
  StoreDetailFamily._()
    : super(
        retry: null,
        name: r'storeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StoreDetailProvider call(String storeId) =>
      StoreDetailProvider._(argument: storeId, from: this);

  @override
  String toString() => r'storeDetailProvider';
}

@ProviderFor(storeMenu)
final storeMenuProvider = StoreMenuFamily._();

final class StoreMenuProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoreMenu>,
          StoreMenu,
          FutureOr<StoreMenu>
        >
    with $FutureModifier<StoreMenu>, $FutureProvider<StoreMenu> {
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

String _$storeMenuHash() => r'dee6b4f4695fbb5d0125fddd75c3f162189ba689';

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

  StoreMenuProvider call(String storeId) =>
      StoreMenuProvider._(argument: storeId, from: this);

  @override
  String toString() => r'storeMenuProvider';
}

/// Lo que coincide con [query] en la carta del negocio (busca el backend).

@ProviderFor(menuSearch)
final menuSearchProvider = MenuSearchFamily._();

/// Lo que coincide con [query] en la carta del negocio (busca el backend).

final class MenuSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MenuItem>>,
          List<MenuItem>,
          FutureOr<List<MenuItem>>
        >
    with $FutureModifier<List<MenuItem>>, $FutureProvider<List<MenuItem>> {
  /// Lo que coincide con [query] en la carta del negocio (busca el backend).
  MenuSearchProvider._({
    required MenuSearchFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'menuSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$menuSearchHash();

  @override
  String toString() {
    return r'menuSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<MenuItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MenuItem>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return menuSearch(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MenuSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$menuSearchHash() => r'f7f42ad20174ffaaee32f80042df8acbb3fcab3f';

/// Lo que coincide con [query] en la carta del negocio (busca el backend).

final class MenuSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MenuItem>>, (String, String)> {
  MenuSearchFamily._()
    : super(
        retry: null,
        name: r'menuSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lo que coincide con [query] en la carta del negocio (busca el backend).

  MenuSearchProvider call(String storeId, String query) =>
      MenuSearchProvider._(argument: (storeId, query), from: this);

  @override
  String toString() => r'menuSearchProvider';
}
