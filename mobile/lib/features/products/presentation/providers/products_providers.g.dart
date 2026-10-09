// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productsRemoteDataSource)
final productsRemoteDataSourceProvider = ProductsRemoteDataSourceProvider._();

final class ProductsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ProductsRemoteDataSource,
          ProductsRemoteDataSource,
          ProductsRemoteDataSource
        >
    with $Provider<ProductsRemoteDataSource> {
  ProductsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProductsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductsRemoteDataSource create(Ref ref) {
    return productsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductsRemoteDataSource>(value),
    );
  }
}

String _$productsRemoteDataSourceHash() =>
    r'36fc7f5660a827f5dddc2ee564c1e8381a5e18a3';

@ProviderFor(productsRepository)
final productsRepositoryProvider = ProductsRepositoryProvider._();

final class ProductsRepositoryProvider
    extends
        $FunctionalProvider<
          ProductsRepository,
          ProductsRepository,
          ProductsRepository
        >
    with $Provider<ProductsRepository> {
  ProductsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductsRepository create(Ref ref) {
    return productsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductsRepository>(value),
    );
  }
}

String _$productsRepositoryHash() =>
    r'd89f42f09c1c38adf183c4f12d406b2d50e0b70d';

/// El delivery del negocio depende de la ubicación de entrega actual.
/// Consulta puntual de un producto para otros features (repetir pedido).

@ProviderFor(getProductDetail)
final getProductDetailProvider = GetProductDetailProvider._();

/// El delivery del negocio depende de la ubicación de entrega actual.
/// Consulta puntual de un producto para otros features (repetir pedido).

final class GetProductDetailProvider
    extends
        $FunctionalProvider<
          GetProductDetail,
          GetProductDetail,
          GetProductDetail
        >
    with $Provider<GetProductDetail> {
  /// El delivery del negocio depende de la ubicación de entrega actual.
  /// Consulta puntual de un producto para otros features (repetir pedido).
  GetProductDetailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getProductDetailProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getProductDetailHash();

  @$internal
  @override
  $ProviderElement<GetProductDetail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetProductDetail create(Ref ref) {
    return getProductDetail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetProductDetail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetProductDetail>(value),
    );
  }
}

String _$getProductDetailHash() => r'eea8747bd8a8957f752b1490b49b4373cd2ba4ff';

@ProviderFor(productDetail)
final productDetailProvider = ProductDetailFamily._();

final class ProductDetailProvider
    extends $FunctionalProvider<AsyncValue<Product>, Product, FutureOr<Product>>
    with $FutureModifier<Product>, $FutureProvider<Product> {
  ProductDetailProvider._({
    required ProductDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productDetailHash();

  @override
  String toString() {
    return r'productDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product> create(Ref ref) {
    final argument = this.argument as String;
    return productDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productDetailHash() => r'2b49f55db89547d00c2073cd4d223b80e3913a1f';

final class ProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product>, String> {
  ProductDetailFamily._()
    : super(
        retry: null,
        name: r'productDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductDetailProvider call(String productId) =>
      ProductDetailProvider._(argument: productId, from: this);

  @override
  String toString() => r'productDetailProvider';
}

/// Selección en curso del detalle de producto. La lógica vive en la entidad;
/// el controller solo expone sus transiciones a la UI.

@ProviderFor(ProductSelectionController)
final productSelectionControllerProvider = ProductSelectionControllerFamily._();

/// Selección en curso del detalle de producto. La lógica vive en la entidad;
/// el controller solo expone sus transiciones a la UI.
final class ProductSelectionControllerProvider
    extends $NotifierProvider<ProductSelectionController, ProductSelection> {
  /// Selección en curso del detalle de producto. La lógica vive en la entidad;
  /// el controller solo expone sus transiciones a la UI.
  ProductSelectionControllerProvider._({
    required ProductSelectionControllerFamily super.from,
    required Product super.argument,
  }) : super(
         retry: null,
         name: r'productSelectionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productSelectionControllerHash();

  @override
  String toString() {
    return r'productSelectionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductSelectionController create() => ProductSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductSelection>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSelectionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productSelectionControllerHash() =>
    r'eb9e9591a27537159dc8b1301dd5e5ba3b5b1a62';

/// Selección en curso del detalle de producto. La lógica vive en la entidad;
/// el controller solo expone sus transiciones a la UI.

final class ProductSelectionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductSelectionController,
          ProductSelection,
          ProductSelection,
          ProductSelection,
          Product
        > {
  ProductSelectionControllerFamily._()
    : super(
        retry: null,
        name: r'productSelectionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Selección en curso del detalle de producto. La lógica vive en la entidad;
  /// el controller solo expone sus transiciones a la UI.

  ProductSelectionControllerProvider call(Product product) =>
      ProductSelectionControllerProvider._(argument: product, from: this);

  @override
  String toString() => r'productSelectionControllerProvider';
}

/// Selección en curso del detalle de producto. La lógica vive en la entidad;
/// el controller solo expone sus transiciones a la UI.

abstract class _$ProductSelectionController
    extends $Notifier<ProductSelection> {
  late final _$args = ref.$arg as Product;
  Product get product => _$args;

  ProductSelection build(Product product);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProductSelection, ProductSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProductSelection, ProductSelection>,
              ProductSelection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
