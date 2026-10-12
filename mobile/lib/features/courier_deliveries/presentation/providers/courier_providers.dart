import 'dart:async';

import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/realtime/realtime_client.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/session/logout_hooks.dart';
import 'package:apamuy/features/courier_deliveries/domain/courier.dart';
import 'package:apamuy/features/courier_deliveries/domain/location_sharing.dart';
import 'package:apamuy/features/courier_deliveries/infrastructure/courier_repository_impl.dart';
import 'package:apamuy/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/partner_session/partner_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'courier_providers.g.dart';

/// Sin WebSocket, cada cuánto se buscan pedidos listos y se revisa la entrega
/// en curso. Con él, los cambios llegan al instante.
const courierPollEvery = Duration(seconds: 10);

/// Cada cuánto, como mucho, manda su ubicación mientras lleva un pedido.
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
  // Con un pedido sigue revisando de fondo: si lo cancelan, deja de compartir la ubicación.
  if (me.isOnline) {
    refreshLive(
      ref,
      events: {RealtimeEvents.courierOrdersChanged},
      every: courierPollEvery,
      foregroundOnly: me.availability != CourierAvailability.busy,
    );
  }
  return (await ref.watch(courierRepositoryProvider).activeDeliveries()).getOrThrow().firstOrNull;
}

/// Id del pedido en curso. Solo avisa cuando cambia de pedido, no en cada
/// consulta.
@riverpod
String? courierActiveOrderId(Ref ref) => ref.watch(courierActiveDeliveryProvider).value?.id;

/// Aviso fijo mientras se comparte la ubicación con la app de fondo.
const courierLocationNotice = BackgroundLocationNotice(
  title: 'Llevas un pedido',
  text: 'Apamuy Socios comparte tu ubicación mientras tienes un pedido',
  channelName: 'Ubicación durante el reparto',
);

/// Metros que debe moverse para mandar una posición nueva.
const courierLocationDistance = 15;

/// Mientras está conectado y lleva un pedido, manda su ubicación para que el
/// cliente lo vea llegar, también con la app de fondo o la pantalla apagada
/// (en Android, con un aviso fijo). Se apaga al entregar, desconectarse o
/// cerrar sesión. El permiso se pide una vez; si lo niega, el estado lo dice.
@riverpod
class CourierLocationSharing extends _$CourierLocationSharing {
  _Tracking? _tracking;
  var _asked = false;

  @override
  CourierLocationStatus build() {
    final online = ref.watch(courierMeProvider.select((me) => me.value?.isOnline ?? false));
    final orderId = ref.watch(courierActiveOrderIdProvider);
    late final _Tracking tracking;
    tracking = _Tracking(ref.read(locationServiceProvider), ref.read(courierRepositoryProvider), (status) {
      if (!tracking.closed) state = status;
    });
    _tracking = tracking;
    ref.onDispose(tracking.stop);

    LocationSharingStep step({required bool foreground}) => locationSharingStep(
      online: online,
      activeOrderId: orderId,
      foreground: foreground,
      running: tracking.running,
    );

    if (step(foreground: true) == LocationSharingStep.stop) {
      tracking.stop();
      return CourierLocationStatus.idle;
    }
    ref
      ..onDispose(ref.read(logoutHooksProvider).add(() async => tracking.stop()))
      // Al volver de los ajustes o del fondo lo intenta de nuevo, sin preguntar.
      ..listen(appForegroundProvider, (_, foreground) {
        if (step(foreground: foreground) == LocationSharingStep.start) unawaited(_start(tracking));
      });
    if (step(foreground: ref.read(appForegroundProvider)) == LocationSharingStep.start) unawaited(_start(tracking));
    return CourierLocationStatus.idle;
  }

  Future<void> _start(_Tracking tracking, {bool? ask}) {
    final asking = ask ?? !_asked;
    _asked = true;
    return tracking.start(ask: asking);
  }

  /// La acción del aviso: volver a pedir el permiso o abrir los ajustes.
  Future<void> fix() async {
    final tracking = _tracking;
    if (tracking == null || tracking.closed) return;
    final location = ref.read(locationServiceProvider);
    switch (state) {
      case CourierLocationStatus.denied:
        await _start(tracking, ask: true);
      case CourierLocationStatus.blocked:
        await location.openSettings(const LocationDenied(forever: true));
      case CourierLocationStatus.gpsOff:
        await location.openSettings(const LocationOff());
      case CourierLocationStatus.idle || CourierLocationStatus.sharing:
        break;
    }
  }
}

/// Un seguimiento: desde que corresponde compartir hasta que deja de corresponder.
class _Tracking {
  _Tracking(this._location, this._repository, this._onStatus);

  final LocationService _location;
  final CourierRepository _repository;
  final void Function(CourierLocationStatus) _onStatus;
  StreamSubscription<GeoCoordinates>? _subscription;
  var _starting = false;
  var _sending = false;
  bool closed = false;

  bool get running => _subscription != null || _starting;

  Future<void> start({required bool ask}) async {
    if (closed || running) return;
    _starting = true;
    try {
      final reading = await _location.current(ask: ask);
      if (closed) return;
      switch (reading) {
        case LocationOff():
          _onStatus(CourierLocationStatus.gpsOff);
        case LocationDenied(:final forever):
          _onStatus(forever ? CourierLocationStatus.blocked : CourierLocationStatus.denied);
        // Sin señal todavía, pero con permiso: el seguimiento la trae.
        case LocationFix() || LocationUnavailable():
          if (reading case LocationFix(:final coordinates)) unawaited(_send(coordinates));
          _subscription = _location
              .watch(interval: courierLocationEvery, distanceFilter: courierLocationDistance, notice: courierLocationNotice)
              .listen(_send, onError: (_) => unawaited(_lost()));
          _onStatus(CourierLocationStatus.sharing);
      }
    } finally {
      _starting = false;
    }
  }

  /// Si apagó el GPS o quitó el permiso a mitad del recorrido. Se reintenta al
  /// volver a la app.
  Future<void> _lost() async {
    await _subscription?.cancel();
    _subscription = null;
    if (closed) return;
    final reading = await _location.current(ask: false);
    if (closed || running) return;
    _onStatus(switch (reading) {
      LocationOff() => CourierLocationStatus.gpsOff,
      LocationDenied(:final forever) => forever ? CourierLocationStatus.blocked : CourierLocationStatus.denied,
      LocationFix() || LocationUnavailable() => CourierLocationStatus.idle,
    });
  }

  /// Si la anterior sigue en camino, esta se descarta: la próxima llega pronto.
  Future<void> _send(GeoCoordinates at) async {
    if (_sending || closed) return;
    _sending = true;
    try {
      await _repository.reportLocation(at);
    } finally {
      _sending = false;
    }
  }

  void stop() {
    closed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
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
