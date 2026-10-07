// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkoutPreferences)
final checkoutPreferencesProvider = CheckoutPreferencesProvider._();

final class CheckoutPreferencesProvider
    extends
        $FunctionalProvider<
          CheckoutPreferences,
          CheckoutPreferences,
          CheckoutPreferences
        >
    with $Provider<CheckoutPreferences> {
  CheckoutPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutPreferencesHash();

  @$internal
  @override
  $ProviderElement<CheckoutPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckoutPreferences create(Ref ref) {
    return checkoutPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutPreferences>(value),
    );
  }
}

String _$checkoutPreferencesHash() =>
    r'3726cd798dcf717be6a4d20909b16fcfb036dbc2';

/// Vive toda la sesión: la hora programada a veces se elige en el negocio
/// (cerrado) antes de llegar al checkout.

@ProviderFor(CheckoutController)
final checkoutControllerProvider = CheckoutControllerProvider._();

/// Vive toda la sesión: la hora programada a veces se elige en el negocio
/// (cerrado) antes de llegar al checkout.
final class CheckoutControllerProvider
    extends $NotifierProvider<CheckoutController, CheckoutState> {
  /// Vive toda la sesión: la hora programada a veces se elige en el negocio
  /// (cerrado) antes de llegar al checkout.
  CheckoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutControllerHash();

  @$internal
  @override
  CheckoutController create() => CheckoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutState>(value),
    );
  }
}

String _$checkoutControllerHash() =>
    r'5c02072822b84cf97543ece2e13dac544f73cdfb';

/// Vive toda la sesión: la hora programada a veces se elige en el negocio
/// (cerrado) antes de llegar al checkout.

abstract class _$CheckoutController extends $Notifier<CheckoutState> {
  CheckoutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CheckoutState, CheckoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckoutState, CheckoutState>,
              CheckoutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
