import 'dart:async';

import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/push/push_providers.dart';
import 'package:apamuy/core/session/logout_hooks.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/device_remote_data_source.dart';
import 'package:apamuy/features/auth/presentation/providers/realtime_session.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_registration.g.dart';

@Riverpod(keepAlive: true)
DeviceRemoteDataSource deviceRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeDeviceRemoteDataSource(ref.watch(fakeBackendProvider))
    : ApiDeviceRemoteDataSource(ref.watch(apiClientProvider));

/// Registra el teléfono para push mientras hay sesión. El estado es el token registrado.
/// La raíz de cada app lo mantiene vivo; antes de cerrar sesión corre [unregister].
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  StreamSubscription<String>? _refresh;

  @override
  String? build() {
    final userId = ref.watch(sessionUserIdProvider);
    ref.onDispose(() => _refresh?.cancel());
    ref.onDispose(ref.read(logoutHooksProvider).add(unregister));
    if (userId != null) unawaited(_register());
    return null;
  }

  Future<void> _register() async {
    final messaging = ref.read(pushMessagingProvider);
    final token = await messaging.token();
    if (token == null) return;
    await _send(token);
    _refresh ??= messaging.onTokenRefresh.listen((token) => unawaited(_send(token)));
  }

  Future<void> _send(String token) async {
    try {
      await ref
          .read(deviceRemoteDataSourceProvider)
          .register(pushToken: token, platform: _platform, app: ref.read(pushAppProvider));
      state = token;
    } on AppException catch (error) {
      // Sin red se reintenta en el próximo inicio de sesión o renovación del token.
      debugPrint('No se pudo registrar el push: $error');
    }
  }

  /// Con el access token aún vigente: el backend deja de enviar avisos a este teléfono.
  Future<void> unregister() async {
    final token = state;
    if (token == null) return;
    state = null;
    try {
      await ref.read(deviceRemoteDataSourceProvider).unregister(token);
    } on AppException catch (error) {
      debugPrint('No se pudo quitar el push: $error');
    }
  }

  static String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
