// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceRemoteDataSource)
final deviceRemoteDataSourceProvider = DeviceRemoteDataSourceProvider._();

final class DeviceRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          DeviceRemoteDataSource,
          DeviceRemoteDataSource,
          DeviceRemoteDataSource
        >
    with $Provider<DeviceRemoteDataSource> {
  DeviceRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceRemoteDataSource create(Ref ref) {
    return deviceRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRemoteDataSource>(value),
    );
  }
}

String _$deviceRemoteDataSourceHash() =>
    r'51b61f431817cd6a636b325b1b605e9ade2e62fb';

/// Registra el teléfono para push mientras hay sesión. El estado es el token registrado.
/// La raíz de cada app lo mantiene vivo; antes de cerrar sesión corre [unregister].

@ProviderFor(PushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Registra el teléfono para push mientras hay sesión. El estado es el token registrado.
/// La raíz de cada app lo mantiene vivo; antes de cerrar sesión corre [unregister].
final class PushRegistrationProvider
    extends $NotifierProvider<PushRegistration, String?> {
  /// Registra el teléfono para push mientras hay sesión. El estado es el token registrado.
  /// La raíz de cada app lo mantiene vivo; antes de cerrar sesión corre [unregister].
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  PushRegistration create() => PushRegistration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pushRegistrationHash() => r'fa515716d5bfdd57b61451587a2e2d6caff71a51';

/// Registra el teléfono para push mientras hay sesión. El estado es el token registrado.
/// La raíz de cada app lo mantiene vivo; antes de cerrar sesión corre [unregister].

abstract class _$PushRegistration extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
