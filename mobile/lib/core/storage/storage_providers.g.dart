// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenStorage)
final tokenStorageProvider = TokenStorageProvider._();

final class TokenStorageProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  TokenStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageHash();

  @$internal
  @override
  $ProviderElement<TokenStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStorage create(Ref ref) {
    return tokenStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorage>(value),
    );
  }
}

String _$tokenStorageHash() => r'a42816fb1cf5af728e44ff5c48bfcaf5dc6b12aa';

@ProviderFor(preferencesStorage)
final preferencesStorageProvider = PreferencesStorageProvider._();

final class PreferencesStorageProvider
    extends
        $FunctionalProvider<
          PreferencesStorage,
          PreferencesStorage,
          PreferencesStorage
        >
    with $Provider<PreferencesStorage> {
  PreferencesStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesStorageHash();

  @$internal
  @override
  $ProviderElement<PreferencesStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreferencesStorage create(Ref ref) {
    return preferencesStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferencesStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferencesStorage>(value),
    );
  }
}

String _$preferencesStorageHash() =>
    r'd004cb7e1f65a3f24a2f9341099b1616b8a9549a';

@ProviderFor(localJsonStore)
final localJsonStoreProvider = LocalJsonStoreProvider._();

final class LocalJsonStoreProvider
    extends $FunctionalProvider<LocalJsonStore, LocalJsonStore, LocalJsonStore>
    with $Provider<LocalJsonStore> {
  LocalJsonStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localJsonStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localJsonStoreHash();

  @$internal
  @override
  $ProviderElement<LocalJsonStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalJsonStore create(Ref ref) {
    return localJsonStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJsonStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJsonStore>(value),
    );
  }
}

String _$localJsonStoreHash() => r'715d37e300f806fe79fd8efc833be8aa19293ed5';
