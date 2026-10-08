import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/realtime/realtime_client.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/auth/presentation/providers/auth_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_session.g.dart';

/// Id del usuario con sesión. Solo avisa cuando cambia la cuenta (no al editar
/// el perfil), así el WebSocket no se reconecta sin motivo.
@Riverpod(keepAlive: true)
String? sessionUserId(Ref ref) => ref.watch(authSessionProvider).value?.id;

/// WebSocket de la cuenta con sesión. Se rehace al entrar o salir; en modo
/// demo o sin sesión no conecta.
@Riverpod(keepAlive: true)
RealtimeClient realtimeClient(Ref ref) {
  final env = ref.watch(appEnvProvider);
  if (env.useFakeData) return const NoRealtimeClient();
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) return const NoRealtimeClient();
  final client = SocketIoRealtimeClient(
    url: realtimeUrl(env.apiBaseUrl),
    accessToken: () async => (await ref.read(tokenStorageProvider).read())?.accessToken,
    // Una llamada autenticada: si el token venció, el AuthInterceptor lo renueva.
    refreshSession: () => ref.read(apiClientProvider).get('/users/me'),
  );
  ref.onDispose(client.dispose);
  return client;
}
