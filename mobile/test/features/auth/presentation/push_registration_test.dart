import 'dart:async';

import 'package:apamuy/core/push/push_messaging.dart';
import 'package:apamuy/core/push/push_providers.dart';
import 'package:apamuy/core/session/logout_hooks.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/device_remote_data_source.dart';
import 'package:apamuy/features/auth/presentation/providers/push_registration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging implements PushMessaging {
  final refresh = StreamController<String>.broadcast();

  @override
  Future<String?> token() async => 'token-1';

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<Map<String, String>> get onOpened => const Stream.empty();
}

class _RecordingDevices implements DeviceRemoteDataSource {
  final calls = <String>[];

  @override
  Future<void> register({required String pushToken, required String platform, required PushApp app}) async =>
      calls.add('register $pushToken ${app.wire}');

  @override
  Future<void> unregister(String pushToken) async => calls.add('unregister $pushToken');
}

void main() {
  test('con sesión registra el teléfono, sigue los tokens nuevos y se quita antes de cerrar sesión', () async {
    final messaging = _FakeMessaging();
    final devices = _RecordingDevices();
    final container = ProviderContainer(
      overrides: [
        sessionUserIdProvider.overrideWithValue('usr_1'),
        pushMessagingProvider.overrideWithValue(messaging),
        pushAppProvider.overrideWithValue(PushApp.partner),
        deviceRemoteDataSourceProvider.overrideWithValue(devices),
      ],
    );
    addTearDown(container.dispose);

    container.read(pushRegistrationProvider);
    await pumpEventQueue();
    expect(devices.calls, ['register token-1 partner']);

    messaging.refresh.add('token-2');
    await pumpEventQueue();
    expect(container.read(pushRegistrationProvider), 'token-2');

    await container.read(logoutHooksProvider).run();
    expect(devices.calls.last, 'unregister token-2');
    expect(container.read(pushRegistrationProvider), isNull);
  });

  test('sin sesión no registra nada', () async {
    final devices = _RecordingDevices();
    final container = ProviderContainer(
      overrides: [
        sessionUserIdProvider.overrideWithValue(null),
        pushMessagingProvider.overrideWithValue(_FakeMessaging()),
        deviceRemoteDataSourceProvider.overrideWithValue(devices),
      ],
    );
    addTearDown(container.dispose);

    container.read(pushRegistrationProvider);
    await pumpEventQueue();
    expect(devices.calls, isEmpty);
  });
}
