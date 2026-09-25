import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/orders/infrastructure/datasources/fake_orders_remote_data_source.dart';
import 'package:chaski/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

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

    test('la misma clave devuelve el mismo pedido, como la API', () async {
      final first = await fake.place(_body(), idempotencyKey: 'key-1');
      final again = await fake.place(_body(), idempotencyKey: 'key-1');
      final other = await fake.place(_body(), idempotencyKey: 'key-2');

      expect(again['id'], first['id']);
      expect(other['id'], isNot(first['id']));
    });
  });
}
