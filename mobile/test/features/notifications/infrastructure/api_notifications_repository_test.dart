import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/infrastructure/api_notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late ApiNotificationsRepository repository;

  setUp(() {
    api = _MockApiClient();
    repository = ApiNotificationsRepository(api);
  });

  test('lee los avisos con el formato del backend', () async {
    when(
      () => api.get('/notifications', query: any(named: 'query')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'items': [
          {
            'id': 'nt_1',
            'kind': 'COURIER_ASSIGNED',
            'title': 'Luis va por tu pedido',
            'body': 'Moto roja · lo recoge en Doña Rosa',
            'at': '2026-09-25T15:00:00.000Z',
            'read': false,
            'orderId': 'ord_1',
            'storeId': null,
          },
          {
            'id': 'nt_2',
            'kind': 'ALGO_NUEVO',
            'title': 'x',
            'body': 'y',
            'at': '2026-09-25T14:00:00.000Z',
            'read': true,
            'orderId': null,
            'storeId': null,
          },
        ],
        'nextCursor': null,
        'unreadCount': 1,
      },
    );

    final notices = (await repository.list()).getOrThrow();

    expect(notices.first.kind, NoticeKind.courierAssigned);
    expect(notices.first.orderId, 'ord_1');
    expect(notices.first.read, isFalse);
    expect(notices.first.at.isUtc, isFalse);
    // Un tipo que la app no conoce no rompe la lista.
    expect(notices.last.kind, NoticeKind.orderConfirmed);
  });

  test('marcar leídos llama a read-all', () async {
    when(
      () => api.post('/notifications/read-all'),
    ).thenAnswer((_) async => null);
    expect((await repository.markAllRead()).isOk, isTrue);
    verify(() => api.post('/notifications/read-all')).called(1);
  });
}
