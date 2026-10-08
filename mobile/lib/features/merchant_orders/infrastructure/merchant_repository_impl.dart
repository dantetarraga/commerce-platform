import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/infrastructure/datasources/merchant_remote_data_source.dart';
import 'package:chaski/features/merchant_orders/infrastructure/models/merchant_json.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/orders/orders_infrastructure.dart';

class MerchantRepositoryImpl implements MerchantRepository {
  const MerchantRepositoryImpl(this._remote);

  final MerchantRemoteDataSource _remote;

  @override
  Future<Result<List<MerchantStore>>> stores() =>
      guard(() async => (await _remote.stores()).map(MerchantJson.store).toList());

  @override
  Future<Result<MerchantStore>> setAcceptingOrders(MerchantStore store, {required bool accepting}) => guard(() async {
    final json = await _remote.setAcceptingOrders(store.id, accepting: accepting);
    return store.copyWith(isAcceptingOrders: json['isAcceptingOrders'] as bool);
  });

  @override
  Future<Result<MerchantBoard>> board() => guard(() async => MerchantJson.board(await _remote.board()));

  @override
  Future<Result<List<StaffOrder>>> todayOrders() =>
      guard(() async => (await _remote.orders(scope: 'today')).map(StaffOrderJson.fromJson).toList());

  @override
  Future<Result<StaffOrder>> accept(String orderId, {required int prepMinutes}) =>
      guard(() async => StaffOrderJson.fromJson(await _remote.accept(orderId, prepMinutes: prepMinutes)));

  @override
  Future<Result<StaffOrder>> markReady(String orderId) =>
      guard(() async => StaffOrderJson.fromJson(await _remote.markReady(orderId)));

  @override
  Future<Result<StaffOrder>> reject(String orderId, {required String reason}) =>
      guard(() async => StaffOrderJson.fromJson(await _remote.reject(orderId, reason: reason)));

  @override
  Future<Result<MerchantCatalog>> products(String storeId, {ProductFilter filter = ProductFilter.all, String query = ''}) =>
      guard(() async => MerchantJson.catalog(await _remote.products(storeId, status: MerchantJson.filterToJson(filter), query: query)));

  @override
  Future<Result<MerchantProduct>> setProductAvailable(MerchantProduct product, {required bool available}) =>
      guard(() async {
        final json = await _remote.setProductAvailable(product.id, available: available);
        return product.copyWith(isAvailable: json['isAvailable'] as bool);
      });

  @override
  Future<Result<MerchantSummary>> summary() => guard(() async => MerchantJson.summary(await _remote.summary()));
}
