// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoritesRepository)
final favoritesRepositoryProvider = FavoritesRepositoryProvider._();

final class FavoritesRepositoryProvider
    extends
        $FunctionalProvider<
          FavoritesRepository,
          FavoritesRepository,
          FavoritesRepository
        >
    with $Provider<FavoritesRepository> {
  FavoritesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoritesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoritesRepository create(Ref ref) {
    return favoritesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesRepository>(value),
    );
  }
}

String _$favoritesRepositoryHash() =>
    r'6d50d50c5a672028aa8c7a1034bcab928dd44141';

/// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.

@ProviderFor(FavoritesController)
final favoritesProvider = FavoritesControllerProvider._();

/// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.
final class FavoritesControllerProvider
    extends $AsyncNotifierProvider<FavoritesController, Favorites> {
  /// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.
  FavoritesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesControllerHash();

  @$internal
  @override
  FavoritesController create() => FavoritesController();
}

String _$favoritesControllerHash() =>
    r'aa9971a12c700b96d3013383b88b425323aae5bd';

/// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.

abstract class _$FavoritesController extends $AsyncNotifier<Favorites> {
  FutureOr<Favorites> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Favorites>, Favorites>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Favorites>, Favorites>,
              AsyncValue<Favorites>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// ¿Este negocio está en favoritos? (falso mientras carga).

@ProviderFor(isFavoriteStore)
final isFavoriteStoreProvider = IsFavoriteStoreFamily._();

/// ¿Este negocio está en favoritos? (falso mientras carga).

final class IsFavoriteStoreProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// ¿Este negocio está en favoritos? (falso mientras carga).
  IsFavoriteStoreProvider._({
    required IsFavoriteStoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteStoreHash();

  @override
  String toString() {
    return r'isFavoriteStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFavoriteStore(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoriteStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteStoreHash() => r'660beb1742862bd583e7d6287e0a3d9be1147091';

/// ¿Este negocio está en favoritos? (falso mientras carga).

final class IsFavoriteStoreFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteStoreFamily._()
    : super(
        retry: null,
        name: r'isFavoriteStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ¿Este negocio está en favoritos? (falso mientras carga).

  IsFavoriteStoreProvider call(String storeId) =>
      IsFavoriteStoreProvider._(argument: storeId, from: this);

  @override
  String toString() => r'isFavoriteStoreProvider';
}

/// ¿Este producto está en favoritos? (falso mientras carga).

@ProviderFor(isFavoriteProduct)
final isFavoriteProductProvider = IsFavoriteProductFamily._();

/// ¿Este producto está en favoritos? (falso mientras carga).

final class IsFavoriteProductProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// ¿Este producto está en favoritos? (falso mientras carga).
  IsFavoriteProductProvider._({
    required IsFavoriteProductFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteProductProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteProductHash();

  @override
  String toString() {
    return r'isFavoriteProductProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFavoriteProduct(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoriteProductProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteProductHash() => r'8919ab44ec318552675d2b3e349286775c4fc3f0';

/// ¿Este producto está en favoritos? (falso mientras carga).

final class IsFavoriteProductFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteProductFamily._()
    : super(
        retry: null,
        name: r'isFavoriteProductProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ¿Este producto está en favoritos? (falso mientras carga).

  IsFavoriteProductProvider call(String productId) =>
      IsFavoriteProductProvider._(argument: productId, from: this);

  @override
  String toString() => r'isFavoriteProductProvider';
}
