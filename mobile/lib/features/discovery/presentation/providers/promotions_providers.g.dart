// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(promotionsRepository)
final promotionsRepositoryProvider = PromotionsRepositoryProvider._();

final class PromotionsRepositoryProvider
    extends
        $FunctionalProvider<
          PromotionsRepository,
          PromotionsRepository,
          PromotionsRepository
        >
    with $Provider<PromotionsRepository> {
  PromotionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PromotionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PromotionsRepository create(Ref ref) {
    return promotionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PromotionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PromotionsRepository>(value),
    );
  }
}

String _$promotionsRepositoryHash() =>
    r'51d80096e80df0b4de6a4ec91be4acb34a36e8b7';

@ProviderFor(promotions)
final promotionsProvider = PromotionsProvider._();

final class PromotionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Promotion>>,
          List<Promotion>,
          FutureOr<List<Promotion>>
        >
    with $FutureModifier<List<Promotion>>, $FutureProvider<List<Promotion>> {
  PromotionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Promotion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Promotion>> create(Ref ref) {
    return promotions(ref);
  }
}

String _$promotionsHash() => r'5644b497658a7f2155b8a16e464d46b4e6a1b21e';
