import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/auth/domain/entities/auth_user.dart';
import 'package:chaski/features/auth/presentation/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session.g.dart';

/// Sesión actual de la app.
///
/// - `AsyncLoading`: restaurando la sesión al arrancar (se muestra el splash).
/// - `AsyncData(null)`: sin sesión.
/// - `AsyncData(user)`: autenticado.
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

  Future<void> logout() async {
    await ref.read(logoutProvider).call();
    state = const AsyncData(null);
  }
}
