// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// El `main` de cada app lo reemplaza con Firebase; en tests y modo demo no hace nada.

@ProviderFor(pushMessaging)
final pushMessagingProvider = PushMessagingProvider._();

/// El `main` de cada app lo reemplaza con Firebase; en tests y modo demo no hace nada.

final class PushMessagingProvider
    extends $FunctionalProvider<PushMessaging, PushMessaging, PushMessaging>
    with $Provider<PushMessaging> {
  /// El `main` de cada app lo reemplaza con Firebase; en tests y modo demo no hace nada.
  PushMessagingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagingHash();

  @$internal
  @override
  $ProviderElement<PushMessaging> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushMessaging create(Ref ref) {
    return pushMessaging(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessaging value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessaging>(value),
    );
  }
}

String _$pushMessagingHash() => r'41e81959109a0c106c95c7091ecf9a4f97a377bd';

/// Qué app corre: el `main` de Socios lo reemplaza con [PushApp.partner].

@ProviderFor(pushApp)
final pushAppProvider = PushAppProvider._();

/// Qué app corre: el `main` de Socios lo reemplaza con [PushApp.partner].

final class PushAppProvider
    extends $FunctionalProvider<PushApp, PushApp, PushApp>
    with $Provider<PushApp> {
  /// Qué app corre: el `main` de Socios lo reemplaza con [PushApp.partner].
  PushAppProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushAppProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushAppHash();

  @$internal
  @override
  $ProviderElement<PushApp> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushApp create(Ref ref) {
    return pushApp(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushApp value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushApp>(value),
    );
  }
}

String _$pushAppHash() => r'05c0edebdc8d096e6f16ce0e999982dd542bc25b';
