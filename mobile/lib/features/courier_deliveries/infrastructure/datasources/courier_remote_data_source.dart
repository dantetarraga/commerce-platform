import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/orders/orders_infrastructure.dart';

/// Fuente remota de `courier/*` (ver `docs/OPERACION.md` §7). JSON crudo.
abstract interface class CourierRemoteDataSource {
  Future<Map<String, dynamic>> me();

  /// [status]: `AVAILABLE` u `OFFLINE`.
  Future<Map<String, dynamic>> setStatus(String status);

  Future<List<Map<String, dynamic>>> available();

  /// [scope]: `active` o `today`.
  Future<List<Map<String, dynamic>>> mine({required String scope});

  Future<Map<String, dynamic>> accept(String orderId);

  Future<Map<String, dynamic>> pickedUp(String orderId);

  /// [method]: `CASH`, `YAPE` o `PLIN`; [amount] como `{amount, currency}`.
  Future<Map<String, dynamic>> delivered(String orderId, {required String method, required Map<String, Object?> amount});

  Future<Map<String, dynamic>> summary();

  /// Última posición del repartidor (`POST /courier/me/location`).
  Future<void> reportLocation({required double lat, required double lng});
}

class ApiCourierRemoteDataSource implements CourierRemoteDataSource {
  const ApiCourierRemoteDataSource(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) => data! as Map<String, dynamic>;

  static List<Map<String, dynamic>> _items(Object? data) => (_map(data)['items'] as List).cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> me() async => _map(await _api.get('/courier/me'));

  @override
  Future<Map<String, dynamic>> setStatus(String status) async =>
      _map(await _api.patch('/courier/me/status', body: {'status': status}));

  @override
  Future<List<Map<String, dynamic>>> available() async =>
      _items(await _api.get('/courier/orders/available', query: {'limit': 50}));

  @override
  Future<List<Map<String, dynamic>>> mine({required String scope}) async =>
      _items(await _api.get('/courier/orders', query: {'scope': scope, 'limit': 50}));

  @override
  Future<Map<String, dynamic>> accept(String orderId) async => _map(await _api.post('/courier/orders/$orderId/accept'));

  @override
  Future<Map<String, dynamic>> pickedUp(String orderId) async =>
      _map(await _api.post('/courier/orders/$orderId/status', body: {'status': 'ON_THE_WAY'}));

  @override
  Future<Map<String, dynamic>> delivered(
    String orderId, {
    required String method,
    required Map<String, Object?> amount,
  }) async => _map(
    await _api.post(
      '/courier/orders/$orderId/status',
      body: {'status': 'DELIVERED', 'collectedMethod': method, 'collectedAmount': amount},
    ),
  );

  @override
  Future<Map<String, dynamic>> summary() async => _map(await _api.get('/courier/me/summary'));

  @override
  Future<void> reportLocation({required double lat, required double lng}) =>
      _api.post('/courier/me/location', body: {'lat': lat, 'lng': lng});
}

/// Modo demo: todo sale de [FakeStaffOrders], compartido con el negocio.
class FakeCourierRemoteDataSource implements CourierRemoteDataSource {
  const FakeCourierRemoteDataSource(this._fake);

  final FakeStaffOrders _fake;

  @override
  Future<Map<String, dynamic>> me() => _fake.courierMe();

  @override
  Future<Map<String, dynamic>> setStatus(String status) => _fake.setCourierStatus(status);

  @override
  Future<List<Map<String, dynamic>>> available() => _fake.availableOrders();

  @override
  Future<List<Map<String, dynamic>>> mine({required String scope}) => _fake.courierOrders(scope: scope);

  @override
  Future<Map<String, dynamic>> accept(String orderId) => _fake.acceptDelivery(orderId);

  @override
  Future<Map<String, dynamic>> pickedUp(String orderId) => _fake.pickedUp(orderId);

  @override
  Future<Map<String, dynamic>> delivered(String orderId, {required String method, required Map<String, Object?> amount}) =>
      _fake.delivered(orderId, method: method, amount: amount);

  @override
  Future<Map<String, dynamic>> summary() => _fake.courierSummary();

  /// En la demo nadie sigue al repartidor.
  @override
  Future<void> reportLocation({required double lat, required double lng}) async {}
}
