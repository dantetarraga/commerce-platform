// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
