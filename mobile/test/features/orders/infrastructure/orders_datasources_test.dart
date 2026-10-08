import 'dart:async';

import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/realtime/realtime_client.dart';
import 'package:chaski/features/orders/infrastructure/datasources/fake_orders_remote_data_source.dart';
import 'package:chaski/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

/// WebSocket de mentira: el test empuja los avisos.
class _FakeRealtime implements RealtimeClient {
  final controller = StreamController<RealtimeEvent>.broadcast();
  final subscribed = <String>{};
  @override
  bool isConnected = true;

  @override
  Stream<RealtimeEvent> get events => controller.stream;

  @override
  void subscribeOrder(String orderId) => subscribed.add(orderId);

  @override
  void unsubscribeOrder(String orderId) => subscribed.remove(orderId);

  @override
  Future<void> dispose() => controller.close();
}

Map<String, dynamic> _order(String status) => {
  'id': 'or_1',
  'status': status,
  'courier': {'name': 'Luis Quispe', 'location': null},
};

Map<String, Object?> _body() => {
  'storeId': 'st_chaski_dorado',
  'items': [
    {
      'productId': 'pr_pollo_medio',
      'variantId': null,
      'optionValueIds': <String>[],
      'quantity': 1,
      'notes': '',
    },
  ],
  'address': {
    'title': 'Casa',
    'street': 'Jr. Túpac Amaru 214',
    'reference': '',
    'latitude': -14.79,
    'longitude': -71.41,
  },
  'payment': {'type': 'YAPE'},
  'couponCode': null,
  'scheduledFor': null,
  'tip': {'amount': 0, 'currency': 'PEN'},
  'notes': '',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiOrdersRemoteDataSource.watch', () {
    test('se suscribe, recarga con order.updated, mueve la moto sin recargar y termina al entregar', () async {
      final api = _MockApiClient();
      final realtime = _FakeRealtime();
      final statuses = ['ON_THE_WAY', 'DELIVERED'];
      when(() => api.get('/orders/or_1')).thenAnswer((_) async => _order(statuses.removeAt(0)));
      final source = ApiOrdersRemoteDataSource(api, realtime: realtime, connectedPollEvery: const Duration(minutes: 5));

      final seen = <Map<String, dynamic>>[];
      final done = source.watch('or_1').listen(seen.add).asFuture<void>();
      await pumpEventQueue();
      expect(realtime.subscribed, {'or_1'});
      expect(seen.single['status'], 'ON_THE_WAY');

      realtime.controller.add(
        const RealtimeEvent('courier.location', {'orderId': 'or_1', 'lat': -14.79, 'lng': -71.41, 'at': '2026-10-08T15:00:00Z'}),
      );
      // De otro pedido: se ignora.
      realtime.controller.add(const RealtimeEvent('order.updated', {'orderId': 'or_2', 'status': 'DELIVERED'}));
      await pumpEventQueue();
      expect(seen, hasLength(2));
      expect((seen.last['courier'] as Map)['location'], {'lat': -14.79, 'lng': -71.41, 'at': '2026-10-08T15:00:00Z'});
      verify(() => api.get('/orders/or_1')).called(1);

      realtime.controller.add(const RealtimeEvent('order.updated', {'orderId': 'or_1', 'status': 'DELIVERED'}));
      await done;
      expect(seen.last['status'], 'DELIVERED');
      expect(realtime.subscribed, isEmpty);
    });

    test('sin WebSocket consulta seguido', () async {
      final api = _MockApiClient();
      final realtime = _FakeRealtime()..isConnected = false;
      final statuses = ['PREPARING', 'READY', 'CANCELLED'];
      when(() => api.get('/orders/or_1')).thenAnswer((_) async => _order(statuses.removeAt(0)));
      final source = ApiOrdersRemoteDataSource(api, realtime: realtime, pollEvery: const Duration(milliseconds: 5));

      final seen = await source.watch('or_1').map((o) => o['status']).toList();
      expect(seen, ['PREPARING', 'READY', 'CANCELLED']);
    });
  });

  group('ApiOrdersRemoteDataSource.place', () {
    test('envía la Idempotency-Key como header', () async {
      final api = _MockApiClient();
      when(
        () => api.post(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'id': 'ord_1'});

      await ApiOrdersRemoteDataSource(
        api,
      ).place(_body(), idempotencyKey: 'abc12345');

      final headers = verify(
        () => api.post(
          '/orders',
          body: any(named: 'body'),
          headers: captureAny(named: 'headers'),
        ),
      ).captured.single;
      expect(headers, {'Idempotency-Key': 'abc12345'});
    });

    test('sin clave no manda el header', () async {
      final api = _MockApiClient();
      when(
        () => api.post(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'id': 'ord_1'});

      await ApiOrdersRemoteDataSource(api).place(_body());

      final headers = verify(
        () => api.post(
          '/orders',
          body: any(named: 'body'),
          headers: captureAny(named: 'headers'),
        ),
      ).captured.single;
      expect(headers, isEmpty);
    });
  });

  group('FakeOrdersRemoteDataSource.place', () {
    late FakeOrdersRemoteDataSource fake;

    setUp(
      () => fake = FakeOrdersRemoteDataSource(
        FakeBackend(
          latency: Duration.zero,
          orderStep: const Duration(hours: 1),
        ),
      ),
    );
    tearDown(() => fake.dispose());

    test('cancela un pedido recién hecho; uno entregado ya no', () async {
      final placed = await fake.place(_body());
      final cancelled = await fake.cancel(placed['id'] as String);
      expect(cancelled['status'], 'CANCELLED');

      final delivered = (await fake.list()).firstWhere((o) => o['status'] == 'DELIVERED');
      await expectLater(
        fake.cancel(delivered['id'] as String),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_STATUS_TRANSITION')),
      );
    });

    test('la misma clave devuelve el mismo pedido, como la API', () async {
      final first = await fake.place(_body(), idempotencyKey: 'key-1');
      final again = await fake.place(_body(), idempotencyKey: 'key-1');
      final other = await fake.place(_body(), idempotencyKey: 'key-2');

      expect(again['id'], first['id']);
      expect(other['id'], isNot(first['id']));
    });
  });
}
