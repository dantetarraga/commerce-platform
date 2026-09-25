import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/notifications/domain/notice.dart';

/// `GET /notifications` y `POST /notifications/read-all`.
class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);

  /// El centro de avisos muestra los más recientes; no pagina todavía.
  static const _limit = 50;

  final ApiClient _api;

  @override
  Future<Result<List<Notice>>> list() => guard(() async {
    final data =
        await _api.get('/notifications', query: {'limit': _limit})
            as Map<String, dynamic>;
    return [
      for (final json in (data['items'] as List).cast<Map<String, dynamic>>())
        NoticeJson.fromJson(json),
    ];
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
