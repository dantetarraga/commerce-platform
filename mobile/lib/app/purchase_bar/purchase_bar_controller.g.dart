// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_bar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Traduce la bolsa y el pedido en curso a la forma de la barra de compra. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.

@ProviderFor(PurchaseBarController)
final purchaseBarControllerProvider = PurchaseBarControllerProvider._();

/// Traduce la bolsa y el pedido en curso a la forma de la barra de compra. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.
final class PurchaseBarControllerProvider
    extends $NotifierProvider<PurchaseBarController, PurchaseBarView> {
  /// Traduce la bolsa y el pedido en curso a la forma de la barra de compra. El pedido
  /// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
  /// de mostrarse.
  PurchaseBarControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseBarControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseBarControllerHash();

  @$internal
  @override
  PurchaseBarController create() => PurchaseBarController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseBarView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseBarView>(value),
    );
  }
}

String _$purchaseBarControllerHash() =>
    r'34a3f916ab98ceebb633f68227e3054c2b0ffd06';

/// Traduce la bolsa y el pedido en curso a la forma de la barra de compra. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.

abstract class _$PurchaseBarController extends $Notifier<PurchaseBarView> {
  PurchaseBarView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PurchaseBarView, PurchaseBarView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PurchaseBarView, PurchaseBarView>,
              PurchaseBarView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
