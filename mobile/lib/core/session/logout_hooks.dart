import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logout_hooks.g.dart';

/// Tareas que deben correr antes de cerrar sesión, mientras el access token aún sirve
/// (p. ej. quitar el push de este teléfono). Quien las necesita se anota; la sesión
/// solo las ejecuta, sin depender de quién son.
class LogoutHooks {
  final _hooks = <Future<void> Function()>[];

  /// Devuelve la función para borrarse.
  void Function() add(Future<void> Function() hook) {
    _hooks.add(hook);
    return () => _hooks.remove(hook);
  }

  Future<void> run() async {
    for (final hook in List.of(_hooks)) {
      await hook();
    }
  }
}

@Riverpod(keepAlive: true)
LogoutHooks logoutHooks(Ref ref) => LogoutHooks();
