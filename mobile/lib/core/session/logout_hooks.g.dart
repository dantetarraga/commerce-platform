// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_hooks.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(logoutHooks)
final logoutHooksProvider = LogoutHooksProvider._();

final class LogoutHooksProvider
    extends $FunctionalProvider<LogoutHooks, LogoutHooks, LogoutHooks>
    with $Provider<LogoutHooks> {
  LogoutHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logoutHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logoutHooksHash();

  @$internal
  @override
  $ProviderElement<LogoutHooks> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogoutHooks create(Ref ref) {
    return logoutHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogoutHooks value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogoutHooks>(value),
    );
  }
}

String _$logoutHooksHash() => r'adbc86b976b7356c1239ec3fe1fdb36cb089b65b';
