// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_searches_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(popularSearchesRepository)
final popularSearchesRepositoryProvider = PopularSearchesRepositoryProvider._();

final class PopularSearchesRepositoryProvider
    extends
        $FunctionalProvider<
          PopularSearchesRepository,
          PopularSearchesRepository,
          PopularSearchesRepository
        >
    with $Provider<PopularSearchesRepository> {
  PopularSearchesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'popularSearchesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$popularSearchesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PopularSearchesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PopularSearchesRepository create(Ref ref) {
    return popularSearchesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PopularSearchesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PopularSearchesRepository>(value),
    );
  }
}

String _$popularSearchesRepositoryHash() =>
    r'616ab3d228e99ac37d2923f224dee6303f9d7da3';

/// "Lo más pedido en Espinar" (estado inicial de Explorar y sugerencias).

@ProviderFor(popularSearches)
final popularSearchesProvider = PopularSearchesProvider._();

/// "Lo más pedido en Espinar" (estado inicial de Explorar y sugerencias).

final class PopularSearchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PopularSearch>>,
          List<PopularSearch>,
          FutureOr<List<PopularSearch>>
        >
    with
        $FutureModifier<List<PopularSearch>>,
        $FutureProvider<List<PopularSearch>> {
  /// "Lo más pedido en Espinar" (estado inicial de Explorar y sugerencias).
  PopularSearchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'popularSearchesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$popularSearchesHash();

  @$internal
  @override
  $FutureProviderElement<List<PopularSearch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PopularSearch>> create(Ref ref) {
    return popularSearches(ref);
  }
}

String _$popularSearchesHash() => r'04e400ea25e703a59a48bf814efcbbdc7d41fa66';
