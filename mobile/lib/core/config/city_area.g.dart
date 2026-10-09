// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_area.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La zona vigente: la guardada al abrir y luego la del backend, que se guarda para
/// la próxima vez. Así un cambio en el panel llega sin publicar otra versión.

@ProviderFor(CurrentCityArea)
final currentCityAreaProvider = CurrentCityAreaProvider._();

/// La zona vigente: la guardada al abrir y luego la del backend, que se guarda para
/// la próxima vez. Así un cambio en el panel llega sin publicar otra versión.
final class CurrentCityAreaProvider
    extends $NotifierProvider<CurrentCityArea, CityArea> {
  /// La zona vigente: la guardada al abrir y luego la del backend, que se guarda para
  /// la próxima vez. Así un cambio en el panel llega sin publicar otra versión.
  CurrentCityAreaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentCityAreaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentCityAreaHash();

  @$internal
  @override
  CurrentCityArea create() => CurrentCityArea();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CityArea value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CityArea>(value),
    );
  }
}

String _$currentCityAreaHash() => r'90f20c207fd6f523c581315ac6e033c24d53fb00';

/// La zona vigente: la guardada al abrir y luego la del backend, que se guarda para
/// la próxima vez. Así un cambio en el panel llega sin publicar otra versión.

abstract class _$CurrentCityArea extends $Notifier<CityArea> {
  CityArea build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CityArea, CityArea>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CityArea, CityArea>,
              CityArea,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
