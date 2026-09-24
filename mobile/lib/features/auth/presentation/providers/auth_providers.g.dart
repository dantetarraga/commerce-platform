// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRemoteDataSource)
final authRemoteDataSourceProvider = AuthRemoteDataSourceProvider._();

final class AuthRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AuthRemoteDataSource,
          AuthRemoteDataSource,
          AuthRemoteDataSource
        >
    with $Provider<AuthRemoteDataSource> {
  AuthRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRemoteDataSource create(Ref ref) {
    return authRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDataSource>(value),
    );
  }
}

String _$authRemoteDataSourceHash() =>
    r'241fa8d108d30b5130554f326a027189c0a9d9c1';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'b2e7273c50e8b72686855166bcae328a041ae7e7';

@ProviderFor(requestCode)
final requestCodeProvider = RequestCodeProvider._();

final class RequestCodeProvider
    extends $FunctionalProvider<RequestCode, RequestCode, RequestCode>
    with $Provider<RequestCode> {
  RequestCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestCodeHash();

  @$internal
  @override
  $ProviderElement<RequestCode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestCode create(Ref ref) {
    return requestCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestCode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestCode>(value),
    );
  }
}

String _$requestCodeHash() => r'1fa0139bb2660484483c6e6cefa6101542cb0c33';

@ProviderFor(verifyCode)
final verifyCodeProvider = VerifyCodeProvider._();

final class VerifyCodeProvider
    extends $FunctionalProvider<VerifyCode, VerifyCode, VerifyCode>
    with $Provider<VerifyCode> {
  VerifyCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyCodeHash();

  @$internal
  @override
  $ProviderElement<VerifyCode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifyCode create(Ref ref) {
    return verifyCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyCode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyCode>(value),
    );
  }
}

String _$verifyCodeHash() => r'a2d8454a40d87dacb9fa05b06640a1e9d081e4ca';

@ProviderFor(completeProfile)
final completeProfileProvider = CompleteProfileProvider._();

final class CompleteProfileProvider
    extends
        $FunctionalProvider<CompleteProfile, CompleteProfile, CompleteProfile>
    with $Provider<CompleteProfile> {
  CompleteProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeProfileHash();

  @$internal
  @override
  $ProviderElement<CompleteProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CompleteProfile create(Ref ref) {
    return completeProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompleteProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompleteProfile>(value),
    );
  }
}

String _$completeProfileHash() => r'a1e029849d9490c0224982b751bfa7be58fbc01e';

@ProviderFor(restoreSession)
final restoreSessionProvider = RestoreSessionProvider._();

final class RestoreSessionProvider
    extends $FunctionalProvider<RestoreSession, RestoreSession, RestoreSession>
    with $Provider<RestoreSession> {
  RestoreSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreSessionHash();

  @$internal
  @override
  $ProviderElement<RestoreSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RestoreSession create(Ref ref) {
    return restoreSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreSession>(value),
    );
  }
}

String _$restoreSessionHash() => r'db86765b1d10e9fa6b22e91b12438b31ff7f00ea';

@ProviderFor(logout)
final logoutProvider = LogoutProvider._();

final class LogoutProvider extends $FunctionalProvider<Logout, Logout, Logout>
    with $Provider<Logout> {
  LogoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logoutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logoutHash();

  @$internal
  @override
  $ProviderElement<Logout> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logout create(Ref ref) {
    return logout(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logout>(value),
    );
  }
}

String _$logoutHash() => r'a5225faea49ec17d4b0131a4d0778c40edc173c4';
