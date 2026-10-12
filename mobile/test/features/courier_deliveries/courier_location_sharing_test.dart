import 'dart:async';

import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/session/logout_hooks.dart';
import 'package:apamuy/features/courier_deliveries/domain/courier.dart';
import 'package:apamuy/features/courier_deliveries/domain/location_sharing.dart';
import 'package:apamuy/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/partner_session/presentation/providers/app_foreground_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CourierRepository {}

class _MockLocation extends Mock implements LocationService {}

final _here = GeoCoordinates.trusted(-14.79, -71.41);
final _there = GeoCoordinates.trusted(-14.80, -71.42);

StaffOrder _delivery() => StaffOrder(
  order: Order(
    id: 'or_1',
    code: '#1',
    store: const OrderStore(id: 's1', name: 'Doña Rosa'),
    lines: const [],
    subtotal: const Money(2000),
    deliveryFee: const Money(300),
    discount: const Money.zero(),
    total: const Money(2300),
    addressTitle: 'Casa',
    addressStreet: 'Jr. Lima 1',
    payment: const YapePayment(),
    status: OrderStatus.onTheWay,
    events: const [],
    placedAt: DateTime(2026, 10, 8, 12),
  ),
  customerName: 'Ana',
  customerPhone: '984123456',
  deliveryLocation: _here,
  pickup: Pickup(address: 'Plaza', location: _here),
  distanceMeters: 800,
);

CourierProfile _profile(CourierAvailability availability) => CourierProfile(
  id: 'c1',
  name: 'Luis Quispe',
  phone: '900000101',
  vehicleLabel: 'Moto roja',
  availability: availability,
);

class _Foreground extends AppForeground {
  _Foreground({required this.initial});

  final bool initial;

  @override
  bool build() => initial;

  void show({required bool visible}) => state = visible;
}

void main() {
  group('locationSharingStep', () {
    LocationSharingStep step({
      bool online = true,
      String? order = 'or_1',
      bool foreground = true,
      bool running = false,
    }) => locationSharingStep(online: online, activeOrderId: order, foreground: foreground, running: running);

    test('sin pedido o desconectado se apaga', () {
      expect(step(order: null), LocationSharingStep.stop);
      expect(step(online: false), LocationSharingStep.stop);
      expect(step(order: null, running: true), LocationSharingStep.stop);
      expect(step(online: false, running: true, foreground: false), LocationSharingStep.stop);
    });

    test('con pedido se inicia a la vista y espera si está de fondo', () {
      expect(step(), LocationSharingStep.start);
      expect(step(foreground: false), LocationSharingStep.wait);
    });

    test('ya iniciado sigue aunque pase al fondo', () {
      expect(step(running: true), LocationSharingStep.keep);
      expect(step(running: true, foreground: false), LocationSharingStep.keep);
    });
  });

  group('courierLocationSharing', () {
    late _MockRepository repo;
    late _MockLocation location;
    late StreamController<GeoCoordinates> positions;
    late LocationReading reading;

    setUpAll(() {
      registerFallbackValue(_here);
      registerFallbackValue(Duration.zero);
      registerFallbackValue(const LocationOff());
    });

    setUp(() {
      repo = _MockRepository();
      location = _MockLocation();
      positions = StreamController<GeoCoordinates>.broadcast();
      reading = LocationFix(_here);
      when(() => location.current(ask: any(named: 'ask'))).thenAnswer((_) async => reading);
      when(
        () => location.watch(
          interval: any(named: 'interval'),
          distanceFilter: any(named: 'distanceFilter'),
          notice: any(named: 'notice'),
        ),
      ).thenAnswer((_) => positions.stream);
      when(() => location.openSettings(any())).thenAnswer((_) async {});
      when(() => repo.available()).thenAnswer((_) async => const Ok(<StaffOrder>[]));
      when(() => repo.reportLocation(any())).thenAnswer((_) async => const Ok(null));
    });

    tearDown(() => positions.close());

    ProviderContainer sharing({
      CourierAvailability availability = CourierAvailability.busy,
      StaffOrder? delivery,
      bool foreground = true,
    }) {
      when(() => repo.me()).thenAnswer((_) async => Ok(_profile(availability)));
      when(() => repo.activeDeliveries()).thenAnswer((_) async => Ok([?delivery]));
      final container = ProviderContainer(
        overrides: [
          courierRepositoryProvider.overrideWithValue(repo),
          locationServiceProvider.overrideWithValue(location),
          appForegroundProvider.overrideWith(() => _Foreground(initial: foreground)),
        ],
      )..listen(courierLocationSharingProvider, (_, _) {});
      return container;
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    void setForeground(ProviderContainer container, {required bool visible}) =>
        (container.read(appForegroundProvider.notifier) as _Foreground).show(visible: visible);

    testWidgets('con un pedido manda la primera posición y sigue con el aviso fijo', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);

      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.sharing);
      verify(() => location.current()).called(1);
      verify(() => repo.reportLocation(_here)).called(1);
      verify(
        () => location.watch(
          interval: courierLocationEvery,
          distanceFilter: courierLocationDistance,
          notice: courierLocationNotice,
        ),
      ).called(1);

      positions.add(_there);
      await settle(tester);
      verify(() => repo.reportLocation(_there)).called(1);
      container.dispose();
    });

    testWidgets('sigue mandándola con la app de fondo', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);
      clearInteractions(repo);

      setForeground(container, visible: false);
      await settle(tester);
      positions.add(_there);
      await settle(tester);

      verify(() => repo.reportLocation(_there)).called(1);
      expect(positions.hasListener, isTrue);
      container.dispose();
    });

    testWidgets('si recibe el pedido con la app de fondo, empieza al volver a la vista', (tester) async {
      final container = sharing(delivery: _delivery(), foreground: false);
      await settle(tester);
      verifyNever(() => location.current(ask: any(named: 'ask')));
      expect(positions.hasListener, isFalse);

      setForeground(container, visible: true);
      await settle(tester);
      expect(positions.hasListener, isTrue);
      container.dispose();
    });

    testWidgets('sin pedido en curso no la manda', (tester) async {
      final container = sharing();
      await settle(tester);
      await tester.pump(courierLocationEvery * 2);
      verifyNever(() => repo.reportLocation(any()));
      verifyNever(() => location.current(ask: any(named: 'ask')));
      container.dispose();
    });

    testWidgets('al terminar el pedido se apaga', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(positions.hasListener, isTrue);

      when(() => repo.activeDeliveries()).thenAnswer((_) async => const Ok(<StaffOrder>[]));
      container.invalidate(courierActiveDeliveryProvider);
      await settle(tester);

      expect(positions.hasListener, isFalse);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.idle);
      container.dispose();
    });

    testWidgets('un corte de red al revisar el pedido no la apaga', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);

      when(() => repo.activeDeliveries()).thenAnswer((_) async => const Err(NetworkFailure()));
      container.invalidate(courierActiveDeliveryProvider);
      await settle(tester);

      expect(positions.hasListener, isTrue);
      container.dispose();
    });

    testWidgets('al desconectarse se apaga', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(positions.hasListener, isTrue);

      when(
        () => repo.setOnline(online: false),
      ).thenAnswer((_) async => Ok(_profile(CourierAvailability.offline)));
      await container.read(courierMeProvider.notifier).setOnline(online: false);
      await settle(tester);

      expect(positions.hasListener, isFalse);
      container.dispose();
    });

    testWidgets('al cerrar sesión se apaga', (tester) async {
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(positions.hasListener, isTrue);

      await container.read(logoutHooksProvider).run();
      await settle(tester);

      expect(positions.hasListener, isFalse);
      container.dispose();
    });

    testWidgets('si niega el permiso lo avisa y puede volver a pedirlo', (tester) async {
      reading = const LocationDenied();
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.denied);
      expect(positions.hasListener, isFalse);

      reading = LocationFix(_here);
      await container.read(courierLocationSharingProvider.notifier).fix();
      await settle(tester);

      verify(() => location.current()).called(2);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.sharing);
      expect(positions.hasListener, isTrue);
      container.dispose();
    });

    testWidgets('bloqueado lleva a los ajustes y reintenta al volver, sin preguntar', (tester) async {
      reading = const LocationDenied(forever: true);
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.blocked);

      await container.read(courierLocationSharingProvider.notifier).fix();
      verify(() => location.openSettings(const LocationDenied(forever: true))).called(1);

      reading = LocationFix(_here);
      setForeground(container, visible: false);
      setForeground(container, visible: true);
      await settle(tester);

      verify(() => location.current(ask: false)).called(1);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.sharing);
      container.dispose();
    });

    testWidgets('con el GPS apagado lo avisa', (tester) async {
      reading = const LocationOff();
      final container = sharing(delivery: _delivery());
      await settle(tester);
      expect(container.read(courierLocationSharingProvider), CourierLocationStatus.gpsOff);

      await container.read(courierLocationSharingProvider.notifier).fix();
      verify(() => location.openSettings(const LocationOff())).called(1);
      container.dispose();
    });
  });
}
