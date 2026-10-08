import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/notifications/domain/notice.dart';

/// `GET /notifications/feed` y `POST /notifications/read-all`.
class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<NoticeFeed>> feed(NoticeFilter filter) => guard(() async {
    final data = await _api.get('/notifications/feed', query: {'filter': filter.apiName}) as Map<String, dynamic>;
    return NoticeJson.feed(data);
  });

  @override
  Future<Result<void>> markAllRead() =>
      guard(() => _api.post('/notifications/read-all'));
}

/// Contrato JSON de un aviso.
abstract final class NoticeJson {
  static const Map<String, NoticeKind> _kinds = {
    'ORDER_CONFIRMED': NoticeKind.orderConfirmed,
    'PREPARING': NoticeKind.preparing,
    'COURIER_ASSIGNED': NoticeKind.courierAssigned,
    'COURIER_NEARBY': NoticeKind.courierNearby,
    'DELIVERED': NoticeKind.delivered,
    'ORDER_CANCELLED': NoticeKind.orderCancelled,
    'PROMOTION': NoticeKind.promotion,
  };

  static const Map<String, NoticeDay> _days = {
    'TODAY': NoticeDay.today,
    'YESTERDAY': NoticeDay.yesterday,
    'EARLIER': NoticeDay.earlier,
  };

  static List<Notice> _list(Object? json) => [
    for (final n in (json as List? ?? const []).cast<Map<String, dynamic>>()) fromJson(n),
  ];

  static NoticeFeed feed(Map<String, dynamic> json) => NoticeFeed(
    thread: _list(json['thread']),
    groups: [
      for (final g in (json['groups'] as List).cast<Map<String, dynamic>>())
        NoticeGroup(day: _days[g['day']] ?? NoticeDay.earlier, items: _list(g['items'])),
    ],
    unreadCount: json['unreadCount'] as int,
    total: json['total'] as int,
  );

  static Notice fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'] as String,
    // Un tipo nuevo del backend no rompe la lista: se muestra como aviso de pedido.
    kind: _kinds[json['kind']] ?? NoticeKind.orderConfirmed,
    title: json['title'] as String,
    body: json['body'] as String,
    at: DateTime.parse(json['at'] as String).toLocal(),
    read: json['read'] as bool? ?? false,
    orderId: json['orderId'] as String?,
    storeId: json['storeId'] as String?,
  );
}
