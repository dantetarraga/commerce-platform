import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/courier_deliveries/domain/courier.dart';
import 'package:apamuy/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/orders/orders_infrastructure.dart';

class CourierRepositoryImpl implements CourierRepository {
  const CourierRepositoryImpl(this._remote);

  final CourierRemoteDataSource _remote;

  static CourierProfile _profile(Map<String, dynamic> json) => CourierProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    vehicleLabel: json['vehicleLabel'] as String,
    availability: switch (json['status']) {
      'AVAILABLE' => CourierAvailability.available,
      'BUSY' => CourierAvailability.busy,
      _ => CourierAvailability.offline,
    },
    activeOrderId: json['activeOrderId'] as String?,
  );

  static CourierSummary _summary(Map<String, dynamic> json) {
    final collected = json['collected'] as Map<String, dynamic>;
    return CourierSummary(
      deliveredCount: json['deliveredCount'] as int,
      total: OrderJson.moneyFromJson(collected['total']),
      cash: OrderJson.moneyFromJson(collected['CASH']),
      yape: OrderJson.moneyFromJson(collected['YAPE']),
      plin: OrderJson.moneyFromJson(collected['PLIN']),
    );
  }

  @override
  Future<Result<CourierProfile>> me() => guard(() async => _profile(await _remote.me()));

  @override
  Future<Result<CourierProfile>> setOnline({required bool online}) =>
      guard(() async => _profile(await _remote.setStatus(online ? 'AVAILABLE' : 'OFFLINE')));

  @override
  Future<Result<List<StaffOrder>>> available() =>
      guard(() async => (await _remote.available()).map(StaffOrderJson.fromJson).toList());

  @override
  Future<Result<List<StaffOrder>>> activeDeliveries() =>
      guard(() async => (await _remote.mine(scope: 'active')).map(StaffOrderJson.fromJson).toList());

  @override
  Future<Result<StaffOrder>> accept(String orderId) =>
      guard(() async => StaffOrderJson.fromJson(await _remote.accept(orderId)));

  @override
  Future<Result<StaffOrder>> pickedUp(String orderId) =>
      guard(() async => StaffOrderJson.fromJson(await _remote.pickedUp(orderId)));

  @override
  Future<Result<StaffOrder>> delivered(String orderId, {required CollectionMethod method, required Money amount}) =>
      guard(
        () async => StaffOrderJson.fromJson(
          await _remote.delivered(orderId, method: StaffOrderJson.methodToJson(method), amount: OrderJson.money(amount)),
        ),
      );

  @override
  Future<Result<CourierSummary>> summary() => guard(() async => _summary(await _remote.summary()));

  @override
  Future<Result<void>> reportLocation(GeoCoordinates at) =>
      guard(() => _remote.reportLocation(lat: at.latitude, lng: at.longitude));
}
