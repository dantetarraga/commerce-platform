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

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
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

String _$categoriesHash() => r'e6be06b2915aed77c249458d9fa19dcc2272f866';

/// Negocios para la ubicación de entrega actual.

@ProviderFor(stores)
final storesProvider = StoresFamily._();

/// Negocios para la ubicación de entrega actual.

final class StoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<PageResult<StoreSummary>>,
          PageResult<StoreSummary>,
          FutureOr<PageResult<StoreSummary>>
        >
    with
        $FutureModifier<PageResult<StoreSummary>>,
        $FutureProvider<PageResult<StoreSummary>> {
  /// Negocios para la ubicación de entrega actual.
  StoresProvider._({
    required StoresFamily super.from,
    required ({StoreSort sort, String? categoryId}) super.argument,
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
  $FutureProviderElement<PageResult<StoreSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PageResult<StoreSummary>> create(Ref ref) {
    final argument = this.argument as ({StoreSort sort, String? categoryId});
    return stores(ref, sort: argument.sort, categoryId: argument.categoryId);
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

String _$storesHash() => r'9708c1e300ed1f0657105ed35a52273296206e09';

/// Negocios para la ubicación de entrega actual.

final class StoresFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PageResult<StoreSummary>>,
          ({StoreSort sort, String? categoryId})
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
  }) => StoresProvider._(
    argument: (sort: sort, categoryId: categoryId),
    from: this,
  );

  @override
  String toString() => r'storesProvider';
}

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.

@ProviderFor(storeDetail)
final storeDetailProvider = StoreDetailFamily._();

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.

final class StoreDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoreDetail>,
          StoreDetail,
          FutureOr<StoreDetail>
        >
    with $FutureModifier<StoreDetail>, $FutureProvider<StoreDetail> {
  /// Distancia, delivery y ETA dependen de la ubicación de entrega actual.
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

String _$storeDetailHash() => r'5916b317057a2aae76dd6c0f13b56d11c0892eb6';

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.

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

  /// Distancia, delivery y ETA dependen de la ubicación de entrega actual.

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
