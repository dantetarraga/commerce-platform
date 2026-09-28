// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Se abre cuando la animación de arranque terminó de mostrarse. Los routers no
/// salen del splash antes, así la marca se ve completa y la salida no se corta.

@ProviderFor(SplashGate)
final splashGateProvider = SplashGateProvider._();

/// Se abre cuando la animación de arranque terminó de mostrarse. Los routers no
/// salen del splash antes, así la marca se ve completa y la salida no se corta.
final class SplashGateProvider extends $NotifierProvider<SplashGate, bool> {
  /// Se abre cuando la animación de arranque terminó de mostrarse. Los routers no
  /// salen del splash antes, así la marca se ve completa y la salida no se corta.
  SplashGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashGateHash();

  @$internal
  @override
  SplashGate create() => SplashGate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$splashGateHash() => r'1b74fa413bc188052c43df374bdcb939491a18eb';

/// Se abre cuando la animación de arranque terminó de mostrarse. Los routers no
/// salen del splash antes, así la marca se ve completa y la salida no se corta.

abstract class _$SplashGate extends $Notifier<bool> {
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
