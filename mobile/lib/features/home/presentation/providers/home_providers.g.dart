// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pedidos entregados por id de negocio ("Lo pediste 4 veces").

@ProviderFor(deliveredCountByStore)
final deliveredCountByStoreProvider = DeliveredCountByStoreProvider._();

/// Pedidos entregados por id de negocio ("Lo pediste 4 veces").

final class DeliveredCountByStoreProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  /// Pedidos entregados por id de negocio ("Lo pediste 4 veces").
  DeliveredCountByStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deliveredCountByStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deliveredCountByStoreHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return deliveredCountByStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$deliveredCountByStoreHash() =>
    r'cb44aaf3bbcc89285cc02805d9afa997391a1758';

/// Ejecuta "Repetir" de punta a punta: carga el negocio, rearma las líneas con
/// [RepeatOrder] y las pone en la bolsa. El estado dice si hay uno en curso.

@ProviderFor(RepeatOrderController)
final repeatOrderControllerProvider = RepeatOrderControllerProvider._();

/// Ejecuta "Repetir" de punta a punta: carga el negocio, rearma las líneas con
/// [RepeatOrder] y las pone en la bolsa. El estado dice si hay uno en curso.
final class RepeatOrderControllerProvider
    extends $NotifierProvider<RepeatOrderController, bool> {
  /// Ejecuta "Repetir" de punta a punta: carga el negocio, rearma las líneas con
  /// [RepeatOrder] y las pone en la bolsa. El estado dice si hay uno en curso.
  RepeatOrderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repeatOrderControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repeatOrderControllerHash();

  @$internal
  @override
  RepeatOrderController create() => RepeatOrderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$repeatOrderControllerHash() =>
    r'50ba5581ff856f306b45c60845f1bcf7beb20fa8';

/// Ejecuta "Repetir" de punta a punta: carga el negocio, rearma las líneas con
/// [RepeatOrder] y las pone en la bolsa. El estado dice si hay uno en curso.

abstract class _$RepeatOrderController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
