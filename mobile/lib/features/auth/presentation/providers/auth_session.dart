import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/session/logout_hooks.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:apamuy/features/auth/presentation/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session.g.dart';

/// Sesión actual: `AsyncLoading` al restaurarla, `AsyncData(null)` sin sesión y
/// `AsyncData(user)` autenticado.
@Riverpod(keepAlive: true)
class AuthSession extends _$AuthSession {
  @override
  Future<AuthUser?> build() async {
    final subscription = ref.watch(sessionEventsProvider).onExpired.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(subscription.cancel);

    final result = await ref.read(restoreSessionProvider).call();
    // Si no se pudo validar (p. ej. sin red), se pide login otra vez: es lo más
    // seguro y el usuario puede reintentar desde ahí.
    return result.fold((user) => user, (_) => null);
  }

  void signedIn(AuthUser user) => state = AsyncData(user);

  /// Datos de la cuenta editados en el perfil.
  void userUpdated(AuthUser user) => state = AsyncData(user);

  Future<void> logout() async {
    // Primero lo que necesita la sesión (p. ej. quitar el push de este teléfono).
    await ref.read(logoutHooksProvider).run();
    await ref.read(logoutProvider).call();
    state = const AsyncData(null);
  }

  /// Si el backend la elimina, la sesión termina; si no (pedido en curso, socio), sigue
  /// abierta y el error explica por qué.
  Future<Result<void>> deleteAccount() async {
    final result = await ref.read(deleteAccountProvider).call();
    if (result is Ok<void>) state = const AsyncData(null);
    return result;
  }
}
