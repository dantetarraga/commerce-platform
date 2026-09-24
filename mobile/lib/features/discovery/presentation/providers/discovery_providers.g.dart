// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localProductsRepository)
final localProductsRepositoryProvider = LocalProductsRepositoryProvider._();

final class LocalProductsRepositoryProvider
    extends
        $FunctionalProvider<
          LocalProductsRepository,
          LocalProductsRepository,
          LocalProductsRepository
        >
    with $Provider<LocalProductsRepository> {
  LocalProductsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localProductsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localProductsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalProductsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalProductsRepository create(Ref ref) {
    return localProductsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalProductsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalProductsRepository>(value),
    );
  }
}

String _$localProductsRepositoryHash() =>
    r'74f6d2891075b470439f5340a3890317384b4ba6';

/// "Hecho en Espinar": productos de la ciudad.

@ProviderFor(localProducts)
final localProductsProvider = LocalProductsProvider._();

/// "Hecho en Espinar": productos de la ciudad.

final class LocalProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductHit>>,
          List<ProductHit>,
          FutureOr<List<ProductHit>>
        >
    with $FutureModifier<List<ProductHit>>, $FutureProvider<List<ProductHit>> {
  /// "Hecho en Espinar": productos de la ciudad.
  LocalProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<ProductHit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductHit>> create(Ref ref) {
    return localProducts(ref);
  }
}

String _$localProductsHash() => r'5fa03e979adfa596f6ab17ceb708d6a7c2b597ef';

/// Momento actual; se recalcula cada 10 minutos (el saludo y las colecciones
/// cambian solos al pasar del desayuno al almuerzo).

@ProviderFor(CurrentMoment)
final currentMomentProvider = CurrentMomentProvider._();

/// Momento actual; se recalcula cada 10 minutos (el saludo y las colecciones
/// cambian solos al pasar del desayuno al almuerzo).
final class CurrentMomentProvider
    extends $NotifierProvider<CurrentMoment, Moment> {
  /// Momento actual; se recalcula cada 10 minutos (el saludo y las colecciones
  /// cambian solos al pasar del desayuno al almuerzo).
  CurrentMomentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMomentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMomentHash();

  @$internal
  @override
  CurrentMoment create() => CurrentMoment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Moment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Moment>(value),
    );
  }
}

String _$currentMomentHash() => r'8e640a3bf4ddd0c7ee769ce1a9ef0a3fcca17205';

/// Momento actual; se recalcula cada 10 minutos (el saludo y las colecciones
/// cambian solos al pasar del desayuno al almuerzo).

abstract class _$CurrentMoment extends $Notifier<Moment> {
  Moment build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Moment, Moment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Moment, Moment>,
              Moment,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
