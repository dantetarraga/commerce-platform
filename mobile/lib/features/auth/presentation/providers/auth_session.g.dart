// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sesión actual de la app.
///
/// - `AsyncLoading`: restaurando la sesión al arrancar (se muestra el splash).
/// - `AsyncData(null)`: sin sesión.
/// - `AsyncData(user)`: autenticado.

@ProviderFor(AuthSession)
final authSessionProvider = AuthSessionProvider._();

/// Sesión actual de la app.
///
/// - `AsyncLoading`: restaurando la sesión al arrancar (se muestra el splash).
/// - `AsyncData(null)`: sin sesión.
/// - `AsyncData(user)`: autenticado.
final class AuthSessionProvider
    extends $AsyncNotifierProvider<AuthSession, AuthUser?> {
  /// Sesión actual de la app.
  ///
  /// - `AsyncLoading`: restaurando la sesión al arrancar (se muestra el splash).
  /// - `AsyncData(null)`: sin sesión.
  /// - `AsyncData(user)`: autenticado.
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  AuthSession create() => AuthSession();
}

String _$authSessionHash() => r'd5a1527db02f665c138816fb25c33476dc585e4b';

/// Sesión actual de la app.
///
/// - `AsyncLoading`: restaurando la sesión al arrancar (se muestra el splash).
/// - `AsyncData(null)`: sin sesión.
/// - `AsyncData(user)`: autenticado.

abstract class _$AuthSession extends $AsyncNotifier<AuthUser?> {
  FutureOr<AuthUser?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthUser?>, AuthUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthUser?>, AuthUser?>,
              AsyncValue<AuthUser?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
