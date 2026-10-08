// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_location.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La dirección seleccionada en `addresses`; sin ella, el GPS y si no, la plaza.

@ProviderFor(CurrentDeliveryLocation)
final currentDeliveryLocationProvider = CurrentDeliveryLocationProvider._();

/// La dirección seleccionada en `addresses`; sin ella, el GPS y si no, la plaza.
final class CurrentDeliveryLocationProvider
    extends $NotifierProvider<CurrentDeliveryLocation, DeliveryLocation> {
  /// La dirección seleccionada en `addresses`; sin ella, el GPS y si no, la plaza.
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
    r'373433f641b1724c7f5de03e8fc48b036cf7c4b2';

/// La dirección seleccionada en `addresses`; sin ella, el GPS y si no, la plaza.

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
