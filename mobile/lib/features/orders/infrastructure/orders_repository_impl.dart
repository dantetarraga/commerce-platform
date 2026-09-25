import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:chaski/features/orders/infrastructure/models/order_json.dart';

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
  Future<Result<List<Order>>> history() => guard(() async => (await _remote.list()).map(OrderJson.fromJson).toList());

  @override
  Future<Result<Order>> cancel(String orderId, {String? reason}) =>
      guard(() async => OrderJson.fromJson(await _remote.cancel(orderId, reason: reason)));

  @override
  Future<Result<Order>> rate(String orderId, {required int rating, String comment = ''}) =>
      guard(() async => OrderJson.fromJson(await _remote.rate(orderId, rating: rating, comment: comment)));
}
