import 'dart:async';

import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/realtime/realtime_client.dart';

/// Fuente remota de `/orders`. Devuelve JSON crudo (ver `OrderJson`).
abstract interface class OrdersRemoteDataSource {
  Future<Map<String, dynamic>> place(Map<String, Object?> body, {String? idempotencyKey});

  Future<Map<String, dynamic>> get(String orderId);

  /// `scope`: `active` (en curso) o `past` (entregados y cancelados).
  Future<List<Map<String, dynamic>>> list({String? scope});

  /// `GET /orders/summary`.
  Future<Map<String, dynamic>> summary();

  Future<Map<String, dynamic>> rate(String orderId, {required int rating, required String comment});

  Future<Map<String, dynamic>> cancel(String orderId, {String? reason});

  /// Cambios del pedido hasta que termina. La API real escucha el WebSocket y
  /// consulta de respaldo; el fake empuja.
  Stream<Map<String, dynamic>> watch(String orderId);
}

class ApiOrdersRemoteDataSource implements OrdersRemoteDataSource {
  const ApiOrdersRemoteDataSource(
    this._api, {
    RealtimeClient realtime = const NoRealtimeClient(),
    this.pollEvery = const Duration(seconds: 8),
    this.connectedPollEvery = const Duration(seconds: 30),
  }) : _realtime = realtime;

  final ApiClient _api;
  final RealtimeClient _realtime;

  /// Sin WebSocket (mala señal): se consulta seguido.
  final Duration pollEvery;

  /// Con WebSocket: solo de respaldo, por si se perdió un aviso.
  final Duration connectedPollEvery;

  @override
  Future<Map<String, dynamic>> place(Map<String, Object?> body, {String? idempotencyKey}) async =>
      (await _api.post(
            '/orders',
            body: body,
            headers: {'Idempotency-Key': ?idempotencyKey},
          ))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> get(String orderId) async => (await _api.get('/orders/$orderId')) as Map<String, dynamic>;

  @override
  Future<List<Map<String, dynamic>>> list({String? scope}) async {
    final data = await _api.get('/orders', query: {'limit': 30, 'scope': ?scope});
    return ((data as Map<String, dynamic>)['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> summary() async => (await _api.get('/orders/summary')) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> rate(String orderId, {required int rating, required String comment}) async =>
      (await _api.post('/orders/$orderId/rating', body: {'rating': rating, 'comment': comment})) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> cancel(String orderId, {String? reason}) async =>
      (await _api.post('/orders/$orderId/cancel', body: {'reason': ?reason})) as Map<String, dynamic>;

  @override
  Stream<Map<String, dynamic>> watch(String orderId) {
    late final StreamController<Map<String, dynamic>> controller;
    StreamSubscription<RealtimeEvent>? events;
    Timer? poll;
    Map<String, dynamic>? last;
    var closed = false;

    Future<void> finish() async {
      if (closed) return;
      closed = true;
      poll?.cancel();
      _realtime.unsubscribeOrder(orderId);
      await events?.cancel();
      await controller.close();
    }

    void emit(Map<String, dynamic> order) {
      if (closed) return;
      last = order;
      controller.add(order);
      final status = order['status'];
      if (status == 'DELIVERED' || status == 'CANCELLED') unawaited(finish());
    }

    Future<void> refresh() async {
      try {
        final order = await get(orderId);
        emit(order);
      } on Object catch (error, stack) {
        // Si ya se mostró el pedido, un fallo de red se reintenta en la próxima consulta.
        if (last == null && !closed) {
          controller.addError(error, stack);
          await finish();
        }
      }
    }

    void schedule() {
      poll?.cancel();
      if (closed) return;
      poll = Timer(_realtime.isConnected ? connectedPollEvery : pollEvery, () async {
        await refresh();
        schedule();
      });
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () async {
        _realtime.subscribeOrder(orderId);
        events = _realtime.events.where((event) => event.orderId == orderId).listen((event) {
          final current = last;
          if (event.name == RealtimeEvents.orderUpdated) {
            unawaited(refresh());
          } else if (event.name == RealtimeEvents.courierLocation && current != null) {
            emit(withCourierLocation(current, event.data));
          }
        });
        await refresh();
        schedule();
      },
      onCancel: finish,
    );
    return controller.stream;
  }

  /// El pedido con la nueva posición del repartidor, sin volver a pedirlo.
  static Map<String, dynamic> withCourierLocation(Map<String, dynamic> order, Map<String, dynamic> event) {
    final courier = order['courier'];
    if (courier is! Map<String, dynamic>) return order;
    return {
      ...order,
      'courier': {
        ...courier,
        'location': {'lat': event['lat'], 'lng': event['lng'], 'at': event['at']},
      },
    };
  }
}
