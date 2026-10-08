import 'dart:async';

import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/realtime/realtime_client.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/courier_deliveries/domain/courier.dart';
import 'package:apamuy/features/courier_deliveries/infrastructure/courier_repository_impl.dart';
import 'package:apamuy/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/partner_session/partner_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'courier_providers.g.dart';

/// Sin WebSocket, cada cuánto se buscan pedidos listos y se revisa la entrega
/// en curso. Con él, los cambios llegan al instante.
const courierPollEvery = Duration(seconds: 10);

/// Cada cuánto manda su ubicación mientras lleva un pedido.
const courierLocationEvery = Duration(seconds: 10);

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

/// Pedidos listos para tomar, si está conectado y libre. Se refrescan al
/// llegar `courier.orders.changed` (o cada [courierPollEvery] sin WebSocket).
@riverpod
Future<List<StaffOrder>> courierAvailableOrders(Ref ref) async {
  final me = await ref.watch(courierMeProvider.future);
  if (me.availability != CourierAvailability.available || !ref.mounted) return const [];
  refreshLive(ref, events: {RealtimeEvents.courierOrdersChanged}, every: courierPollEvery);
  return (await ref.watch(courierRepositoryProvider).available()).getOrThrow();
}

/// El pedido que está llevando (o null). Conectado, se revisa por si lo
/// cancelan o cambia.
@riverpod
Future<StaffOrder?> courierActiveDelivery(Ref ref) async {
  final me = await ref.watch(courierMeProvider.future);
  if (!ref.mounted) return null;
  if (me.isOnline) refreshLive(ref, events: {RealtimeEvents.courierOrdersChanged}, every: courierPollEvery);
  return (await ref.watch(courierRepositoryProvider).activeDeliveries()).getOrThrow().firstOrNull;
}

/// Id del pedido en curso. Solo avisa cuando cambia de pedido, no en cada
/// consulta.
@riverpod
String? courierActiveOrderId(Ref ref) => ref.watch(courierActiveDeliveryProvider).value?.id;

/// Mientras lleva un pedido y la app está a la vista, manda su ubicación cada
/// [courierLocationEvery] para que el cliente lo vea llegar. El permiso se pide
/// una vez; sin permiso o sin señal, simplemente no manda nada.
@riverpod
void courierLocationSharing(Ref ref) {
  final orderId = ref.watch(courierActiveOrderIdProvider);
  if (orderId == null || !ref.watch(appForegroundProvider)) return;
  final location = ref.read(locationServiceProvider);
  final repository = ref.read(courierRepositoryProvider);
  var ask = true;
  var sending = false;
  Future<void> send() async {
    if (sending) return;
    sending = true;
    try {
      final reading = await location.current(ask: ask);
      ask = false;
      if (reading case LocationFix(:final coordinates) when ref.mounted) await repository.reportLocation(coordinates);
    } finally {
      sending = false;
    }
  }

  unawaited(send());
  final timer = Timer.periodic(courierLocationEvery, (_) => unawaited(send()));
  ref.onDispose(timer.cancel);
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
