// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Id del usuario con sesión. Solo avisa cuando cambia la cuenta (no al editar
/// el perfil), así el WebSocket no se reconecta sin motivo.

@ProviderFor(sessionUserId)
final sessionUserIdProvider = SessionUserIdProvider._();

/// Id del usuario con sesión. Solo avisa cuando cambia la cuenta (no al editar
/// el perfil), así el WebSocket no se reconecta sin motivo.

final class SessionUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Id del usuario con sesión. Solo avisa cuando cambia la cuenta (no al editar
  /// el perfil), así el WebSocket no se reconecta sin motivo.
  SessionUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return sessionUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$sessionUserIdHash() => r'bc8d3225580da9d7fe707aa54f5162c42dd5c221';

/// WebSocket de la cuenta con sesión. Se rehace al entrar o salir; en modo
/// demo o sin sesión no conecta.

@ProviderFor(realtimeClient)
final realtimeClientProvider = RealtimeClientProvider._();

/// WebSocket de la cuenta con sesión. Se rehace al entrar o salir; en modo
/// demo o sin sesión no conecta.

final class RealtimeClientProvider
    extends $FunctionalProvider<RealtimeClient, RealtimeClient, RealtimeClient>
    with $Provider<RealtimeClient> {
  /// WebSocket de la cuenta con sesión. Se rehace al entrar o salir; en modo
  /// demo o sin sesión no conecta.
  RealtimeClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realtimeClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realtimeClientHash();

  @$internal
  @override
  $ProviderElement<RealtimeClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealtimeClient create(Ref ref) {
    return realtimeClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealtimeClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealtimeClient>(value),
    );
  }
}

String _$realtimeClientHash() => r'9d3e4fd4957e0a4841d85d4d8a3da395b5c39cfa';
