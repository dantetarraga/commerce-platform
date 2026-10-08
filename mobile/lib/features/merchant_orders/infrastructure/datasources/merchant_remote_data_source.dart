import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/orders/orders_infrastructure.dart';

/// Fuente remota de `merchant/*` (ver `docs/OPERACION.md` §7). JSON crudo.
abstract interface class MerchantRemoteDataSource {
  Future<List<Map<String, dynamic>>> stores();

  Future<Map<String, dynamic>> setAcceptingOrders(String storeId, {required bool accepting});

  /// [scope]: `active` o `today`.
  Future<List<Map<String, dynamic>>> orders({required String scope});

  /// `{ columns: [{ key, count, items }] }` (`GET /merchant/board`).
  Future<Map<String, dynamic>> board();

  Future<Map<String, dynamic>> accept(String orderId, {required int prepMinutes});

  Future<Map<String, dynamic>> markReady(String orderId);

  Future<Map<String, dynamic>> reject(String orderId, {required String reason});

  /// `{ counts, sections }` con [status] (`all`, `available`, `sold_out`) y la búsqueda [query].
  Future<Map<String, dynamic>> products(String storeId, {String status = 'all', String query = ''});

  Future<Map<String, dynamic>> setProductAvailable(String productId, {required bool available});

  Future<Map<String, dynamic>> summary();
}

class ApiMerchantRemoteDataSource implements MerchantRemoteDataSource {
  const ApiMerchantRemoteDataSource(this._api);

  final ApiClient _api;

  static List<Map<String, dynamic>> _list(Object? data) => (data! as List).cast<Map<String, dynamic>>();

  static Map<String, dynamic> _map(Object? data) => data! as Map<String, dynamic>;

  @override
  Future<List<Map<String, dynamic>>> stores() async => _list(await _api.get('/merchant/stores'));

  @override
  Future<Map<String, dynamic>> setAcceptingOrders(String storeId, {required bool accepting}) async =>
      _map(await _api.patch('/merchant/stores/$storeId', body: {'isAcceptingOrders': accepting}));

  @override
  Future<Map<String, dynamic>> board() async => _map(await _api.get('/merchant/board'));

  @override
  Future<List<Map<String, dynamic>>> orders({required String scope}) async {
    final data = await _api.get('/merchant/orders', query: {'scope': scope, 'limit': 50});
    return _list(_map(data)['items']);
  }

  @override
  Future<Map<String, dynamic>> accept(String orderId, {required int prepMinutes}) async =>
      _map(await _api.post('/merchant/orders/$orderId/accept', body: {'prepMinutes': prepMinutes}));

  @override
  Future<Map<String, dynamic>> markReady(String orderId) async =>
      _map(await _api.post('/merchant/orders/$orderId/status', body: {'status': 'READY'}));

  @override
  Future<Map<String, dynamic>> reject(String orderId, {required String reason}) async =>
      _map(await _api.post('/merchant/orders/$orderId/cancel', body: {'reason': reason}));

  @override
  Future<Map<String, dynamic>> products(String storeId, {String status = 'all', String query = ''}) async => _map(
    await _api.get('/merchant/stores/$storeId/products', query: {'status': status, if (query.trim().isNotEmpty) 'q': query.trim()}),
  );

  @override
  Future<Map<String, dynamic>> setProductAvailable(String productId, {required bool available}) async =>
      _map(await _api.patch('/merchant/products/$productId', body: {'isAvailable': available}));

  @override
  Future<Map<String, dynamic>> summary() async => _map(await _api.get('/merchant/summary'));
}

/// Modo demo: todo sale de [FakeStaffOrders], compartido con el repartidor.
class FakeMerchantRemoteDataSource implements MerchantRemoteDataSource {
  const FakeMerchantRemoteDataSource(this._fake);

  final FakeStaffOrders _fake;

  @override
  Future<List<Map<String, dynamic>>> stores() => _fake.merchantStores();

  @override
  Future<Map<String, dynamic>> setAcceptingOrders(String storeId, {required bool accepting}) =>
      _fake.setAcceptingOrders(storeId, accepting: accepting);

  @override
  Future<List<Map<String, dynamic>>> orders({required String scope}) => _fake.merchantOrders(scope: scope);

  @override
  Future<Map<String, dynamic>> board() => _fake.merchantBoard();

  @override
  Future<Map<String, dynamic>> accept(String orderId, {required int prepMinutes}) =>
      _fake.accept(orderId, prepMinutes: prepMinutes);

  @override
  Future<Map<String, dynamic>> markReady(String orderId) => _fake.markReady(orderId);

  @override
  Future<Map<String, dynamic>> reject(String orderId, {required String reason}) => _fake.reject(orderId, reason: reason);

  @override
  Future<Map<String, dynamic>> products(String storeId, {String status = 'all', String query = ''}) =>
      _fake.products(storeId, status: status, query: query);

  @override
  Future<Map<String, dynamic>> setProductAvailable(String productId, {required bool available}) =>
      _fake.setProductAvailable(productId, available: available);

  @override
  Future<Map<String, dynamic>> summary() => _fake.merchantSummary();
}
