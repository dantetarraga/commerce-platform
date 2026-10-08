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

  test('lee el feed tal como lo arma el backend', () async {
    Map<String, Object?> notice(String id, String kind, {bool read = false, String? orderId}) => {
      'id': id,
      'kind': kind,
      'title': 'Luis va por tu pedido',
      'body': 'Moto roja',
      'at': '2026-09-25T15:00:00.000Z',
      'read': read,
      'orderId': orderId,
      'storeId': null,
    };
    when(() => api.get('/notifications/feed', query: any(named: 'query'))).thenAnswer(
      (_) async => <String, dynamic>{
        'thread': [notice('t1', 'ORDER_CONFIRMED', orderId: 'ord_1'), notice('t2', 'COURIER_ASSIGNED', orderId: 'ord_1')],
        'groups': [
          {
            'day': 'TODAY',
            'items': [notice('n1', 'PROMOTION')],
          },
          {
            'day': 'EARLIER',
            'items': [notice('n2', 'ALGO_NUEVO', read: true)],
          },
        ],
        'unreadCount': 3,
        'total': 4,
      },
    );

    final feed = (await repository.feed(NoticeFilter.orders)).getOrThrow();

    verify(() => api.get('/notifications/feed', query: {'filter': 'orders'})).called(1);
    expect(feed.thread.map((n) => n.kind), [NoticeKind.orderConfirmed, NoticeKind.courierAssigned]);
    expect(feed.thread.first.at.isUtc, isFalse);
    expect(feed.groups.map((g) => g.day), [NoticeDay.today, NoticeDay.earlier]);
    // Un tipo que la app no conoce no rompe la lista.
    expect(feed.groups.last.items.single.kind, NoticeKind.orderConfirmed);
    expect((feed.unreadCount, feed.total), (3, 4));
  });

  test('marcar leídos llama a read-all', () async {
    when(
      () => api.post('/notifications/read-all'),
    ).thenAnswer((_) async => null);
    expect((await repository.markAllRead()).isOk, isTrue);
    verify(() => api.post('/notifications/read-all')).called(1);
  });
}
