import 'dart:async';

import 'package:chaski/core/network/api_client.dart';

/// Fuente remota de `/orders`. Devuelve JSON crudo (ver `OrderJson`).
abstract interface class OrdersRemoteDataSource {
  Future<Map<String, dynamic>> place(Map<String, Object?> body);

  Future<Map<String, dynamic>> get(String orderId);

  Future<List<Map<String, dynamic>>> list();

  Future<Map<String, dynamic>> rate(String orderId, {required int rating, required String comment});

  /// Cambios del pedido. La API real consulta periódicamente; el fake empuja.
  Stream<Map<String, dynamic>> watch(String orderId);
}

class ApiOrdersRemoteDataSource implements OrdersRemoteDataSource {
  const ApiOrdersRemoteDataSource(this._api, {this.pollEvery = const Duration(seconds: 8)});

  final ApiClient _api;
  final Duration pollEvery;

  @override
  Future<Map<String, dynamic>> place(Map<String, Object?> body) async =>
      (await _api.post('/orders', body: body)) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> get(String orderId) async => (await _api.get('/orders/$orderId')) as Map<String, dynamic>;

  @override
  Future<List<Map<String, dynamic>>> list() async {
    final data = await _api.get('/orders', query: {'limit': 30});
    return ((data as Map<String, dynamic>)['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> rate(String orderId, {required int rating, required String comment}) async =>
      (await _api.post('/orders/$orderId/rating', body: {'rating': rating, 'comment': comment})) as Map<String, dynamic>;

  @override
  Stream<Map<String, dynamic>> watch(String orderId) async* {
    // Sondeo simple hasta que el pedido termina (luego: push/WebSocket).
    while (true) {
      final order = await get(orderId);
      yield order;
      final status = order['status'];
      if (status == 'DELIVERED' || status == 'CANCELLED') return;
      await Future<void>.delayed(pollEvery);
    }
  }
}
