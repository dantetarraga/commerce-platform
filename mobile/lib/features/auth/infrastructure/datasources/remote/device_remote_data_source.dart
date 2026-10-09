import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/core/push/push_messaging.dart';

/// Teléfonos que reciben push de la cuenta (`/users/me/devices`).
abstract interface class DeviceRemoteDataSource {
  Future<void> register({required String pushToken, required String platform, required PushApp app});

  Future<void> unregister(String pushToken);
}

class ApiDeviceRemoteDataSource implements DeviceRemoteDataSource {
  const ApiDeviceRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<void> register({required String pushToken, required String platform, required PushApp app}) =>
      _api.put('/users/me/devices', body: {'pushToken': pushToken, 'platform': platform, 'app': app.wire});

  @override
  Future<void> unregister(String pushToken) => _api.delete('/users/me/devices', body: {'pushToken': pushToken});
}

/// Modo demo: no hay push, solo la demora de red.
class FakeDeviceRemoteDataSource implements DeviceRemoteDataSource {
  const FakeDeviceRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<void> register({required String pushToken, required String platform, required PushApp app}) =>
      _backend.delay();

  @override
  Future<void> unregister(String pushToken) => _backend.delay();
}
