import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/courier_repository_impl.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'courier_providers.g.dart';

/// Cada cuánto se buscan pedidos listos y se revisa la entrega en curso.
const courierPollEvery = Duration(seconds: 10);

@Riverpod(keepAlive: true)
CourierRemoteDataSource courierRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeCourierRemoteDataSource(ref.watch(fakeStaffOrdersProvider))
    : ApiCourierRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
CourierRepository courierRepository(Ref ref) => CourierRepositoryImpl(ref.watch(courierRemoteDataSourceProvider));

/// El repartidor y su disponibilidad.
@riverpod
class CourierMe extends _$CourierMe {
  @override
  Future<CourierProfile> build() => ref.watch(courierRepositoryProvider).me().then((r) => r.getOrThrow());

  Future<Failure?> setOnline({required bool online}) async {
    final result = await ref.read(courierRepositoryProvider).setOnline(online: online);
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}

/// Pedidos listos para tomar. Solo se consultan (cada [courierPollEvery], con
/// la app a la vista) si está conectado y libre.
@riverpod
Future<List<StaffOrder>> courierAvailableOrders(Ref ref) async {
  final me = await ref.watch(courierMeProvider.future);
  if (me.availability != CourierAvailability.available || !ref.mounted) return const [];
  pollWhileForeground(ref, courierPollEvery);
  return (await ref.watch(courierRepositoryProvider).available()).getOrThrow();
}

/// El pedido que está llevando (o null). Conectado, se revisa cada
/// [courierPollEvery] por si lo cancelan o cambia.
@riverpod
Future<StaffOrder?> courierActiveDelivery(Ref ref) async {
  final me = await ref.watch(courierMeProvider.future);
  if (!ref.mounted) return null;
  if (me.isOnline) pollWhileForeground(ref, courierPollEvery);
  return (await ref.watch(courierRepositoryProvider).activeDeliveries()).getOrThrow().firstOrNull;
}

@riverpod
Future<CourierSummary> courierSummary(Ref ref) =>
    ref.watch(courierRepositoryProvider).summary().then((r) => r.getOrThrow());

/// Tomar, recoger y entregar. Al terminar refresca todo lo del repartidor.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
@Riverpod(keepAlive: true)
class CourierActions extends _$CourierActions {
  @override
  void build() {}

  CourierRepository get _repo => ref.read(courierRepositoryProvider);

  Future<Failure?> accept(String orderId) => _run(() => _repo.accept(orderId));

  Future<Failure?> pickedUp(String orderId) => _run(() => _repo.pickedUp(orderId));

  Future<Failure?> delivered(String orderId, {required CollectionMethod method, required Money amount}) =>
      _run(() => _repo.delivered(orderId, method: method, amount: amount));

  Future<Failure?> _run(Future<Result<StaffOrder>> Function() action) async {
    final result = await action();
    if (!ref.mounted) return null;
    ref
      ..invalidate(courierMeProvider)
      ..invalidate(courierActiveDeliveryProvider)
      ..invalidate(courierAvailableOrdersProvider)
      ..invalidate(courierSummaryProvider);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}
