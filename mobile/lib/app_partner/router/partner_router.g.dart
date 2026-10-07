// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Router de Apamuy Socios. Entra quien tiene rol de negocio o repartidor;
/// el resto ve [NotPartnerPage].

@ProviderFor(partnerRouter)
final partnerRouterProvider = PartnerRouterProvider._();

/// Router de Apamuy Socios. Entra quien tiene rol de negocio o repartidor;
/// el resto ve [NotPartnerPage].

final class PartnerRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Router de Apamuy Socios. Entra quien tiene rol de negocio o repartidor;
  /// el resto ve [NotPartnerPage].
  PartnerRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partnerRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partnerRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return partnerRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$partnerRouterHash() => r'6ca6363de875a3ea5e6dfbc5901f4cc19d5eb6bc';
