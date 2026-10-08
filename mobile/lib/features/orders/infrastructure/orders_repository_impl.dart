import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:apamuy/features/orders/infrastructure/models/order_json.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote);

  final OrdersRemoteDataSource _remote;

  @override
  Future<Result<Order>> placeOrder(PlaceOrderRequest request, {String? idempotencyKey}) => guard(
    () async => OrderJson.fromJson(await _remote.place(OrderJson.requestToJson(request), idempotencyKey: idempotencyKey)),
  );

  @override
  Stream<Order> watch(String orderId) => _remote.watch(orderId).map(OrderJson.fromJson);

  @override
  Future<Result<Order>> getOrder(String orderId) => guard(() async => OrderJson.fromJson(await _remote.get(orderId)));

  @override
  Future<Result<OrderLists>> history() => guard(() async {
    final (active, past) = (_remote.list(scope: 'active'), _remote.list(scope: 'past'));
    return OrderLists(
      active: (await active).map(OrderJson.fromJson).toList(),
      past: (await past).map(OrderJson.fromJson).toList(),
    );
  });

  @override
  Future<Result<OrdersSummary>> summary() => guard(() async {
    final json = await _remote.summary();
    return OrdersSummary(
      orderCount: json['orderCount'] as int,
      activeCount: json['activeCount'] as int,
      saved: OrderJson.moneyFromJson(json['saved']),
      latestOrderId: json['latestOrderId'] as String?,
      repeat: [
        for (final r in (json['repeat'] as List).cast<Map<String, dynamic>>())
          RepeatEntry(order: OrderJson.fromJson(r['order'] as Map<String, dynamic>), deliveredCount: r['deliveredCount'] as int),
      ],
    );
  });

  @override
  Future<Result<Order>> cancel(String orderId, {String? reason}) =>
      guard(() async => OrderJson.fromJson(await _remote.cancel(orderId, reason: reason)));

  @override
  Future<Result<Order>> rate(String orderId, {required int rating, String comment = ''}) =>
      guard(() async => OrderJson.fromJson(await _remote.rate(orderId, rating: rating, comment: comment)));
}
