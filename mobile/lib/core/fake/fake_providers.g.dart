// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fakeBackend)
final fakeBackendProvider = FakeBackendProvider._();

final class FakeBackendProvider
    extends $FunctionalProvider<FakeBackend, FakeBackend, FakeBackend>
    with $Provider<FakeBackend> {
  FakeBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeBackendHash();

  @$internal
  @override
  $ProviderElement<FakeBackend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeBackend create(Ref ref) {
    return fakeBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeBackend>(value),
    );
  }
}

String _$fakeBackendHash() => r'e0459b271b7955f2d2d30ce8d90cb65c40859e24';
