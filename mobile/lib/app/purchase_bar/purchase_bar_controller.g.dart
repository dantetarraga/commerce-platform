// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_bar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Traduce la bolsa y el pedido en curso a la barra de compra. El pedido activo
/// tiene prioridad; uno entregado y ya calificado deja de mostrarse.

@ProviderFor(purchaseBar)
final purchaseBarProvider = PurchaseBarProvider._();

/// Traduce la bolsa y el pedido en curso a la barra de compra. El pedido activo
/// tiene prioridad; uno entregado y ya calificado deja de mostrarse.

final class PurchaseBarProvider
    extends
        $FunctionalProvider<PurchaseBarView, PurchaseBarView, PurchaseBarView>
    with $Provider<PurchaseBarView> {
  /// Traduce la bolsa y el pedido en curso a la barra de compra. El pedido activo
  /// tiene prioridad; uno entregado y ya calificado deja de mostrarse.
  PurchaseBarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseBarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseBarHash();

  @$internal
  @override
  $ProviderElement<PurchaseBarView> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurchaseBarView create(Ref ref) {
    return purchaseBar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseBarView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseBarView>(value),
    );
  }
}

String _$purchaseBarHash() => r'62186758725ae2f7149cc1bec9af37f364895b1e';

/// Cuenta las veces que la bolsa recibió algo nuevo (el nudo salta). Escucha la
/// bolsa en vez de compararla en un `build`, así recalcular la barra no tiene efectos.

@ProviderFor(PurchaseBarPulse)
final purchaseBarPulseProvider = PurchaseBarPulseProvider._();

/// Cuenta las veces que la bolsa recibió algo nuevo (el nudo salta). Escucha la
/// bolsa en vez de compararla en un `build`, así recalcular la barra no tiene efectos.
final class PurchaseBarPulseProvider
    extends $NotifierProvider<PurchaseBarPulse, int> {
  /// Cuenta las veces que la bolsa recibió algo nuevo (el nudo salta). Escucha la
  /// bolsa en vez de compararla en un `build`, así recalcular la barra no tiene efectos.
  PurchaseBarPulseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseBarPulseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseBarPulseHash();

  @$internal
  @override
  PurchaseBarPulse create() => PurchaseBarPulse();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$purchaseBarPulseHash() => r'3a275a7c6fdfdd8e0a66bc9fefe239c7df2fc6f8';

/// Cuenta las veces que la bolsa recibió algo nuevo (el nudo salta). Escucha la
/// bolsa en vez de compararla en un `build`, así recalcular la barra no tiene efectos.

abstract class _$PurchaseBarPulse extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
