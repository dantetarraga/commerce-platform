// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_location.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fase 1: centro de Espinar. En la Fase 2 lo reemplaza la dirección
/// seleccionada en el feature `addresses` (o la ubicación del GPS).

@ProviderFor(CurrentDeliveryLocation)
final currentDeliveryLocationProvider = CurrentDeliveryLocationProvider._();

/// Fase 1: centro de Espinar. En la Fase 2 lo reemplaza la dirección
/// seleccionada en el feature `addresses` (o la ubicación del GPS).
final class CurrentDeliveryLocationProvider
    extends $NotifierProvider<CurrentDeliveryLocation, DeliveryLocation> {
  /// Fase 1: centro de Espinar. En la Fase 2 lo reemplaza la dirección
  /// seleccionada en el feature `addresses` (o la ubicación del GPS).
  CurrentDeliveryLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDeliveryLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDeliveryLocationHash();

  @$internal
  @override
  CurrentDeliveryLocation create() => CurrentDeliveryLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeliveryLocation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeliveryLocation>(value),
    );
  }
}

String _$currentDeliveryLocationHash() =>
    r'43498d4c4ed73f37f24c59bdb8da3af366fd80f5';

/// Fase 1: centro de Espinar. En la Fase 2 lo reemplaza la dirección
/// seleccionada en el feature `addresses` (o la ubicación del GPS).

abstract class _$CurrentDeliveryLocation extends $Notifier<DeliveryLocation> {
  DeliveryLocation build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DeliveryLocation, DeliveryLocation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeliveryLocation, DeliveryLocation>,
              DeliveryLocation,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
