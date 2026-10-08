import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/courier_deliveries/domain/courier.dart';
import 'package:apamuy/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/partner_session/presentation/providers/app_foreground_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CourierRepository {}

class _MockLocation extends Mock implements LocationService {}

final _here = GeoCoordinates.trusted(-14.79, -71.41);

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

class _Foreground extends AppForeground {
  @override
  bool build() => true;

  void show({required bool visible}) => state = visible;
}

CourierProfile _profile(CourierAvailability availability) => CourierProfile(
  id: 'c1',
  name: 'Luis Quispe',
  phone: '900000101',
  vehicleLabel: 'Moto roja',
  availability: availability,
);

void main() {
  late _MockRepository repo;

  /// Contenedor con el repositorio falso que mantiene vivo a [watched].
  ProviderContainer containerFor(CourierAvailability availability, ProviderListenable<Object?> watched) {
    when(() => repo.me()).thenAnswer((_) async => Ok(_profile(availability)));
    when(() => repo.available()).thenAnswer((_) async => const Ok(<StaffOrder>[]));
    when(() => repo.activeDeliveries()).thenAnswer((_) async => const Ok(<StaffOrder>[]));
    final container = ProviderContainer(
      overrides: [
        courierRepositoryProvider.overrideWithValue(repo),
        appForegroundProvider.overrideWith(_Foreground.new),
      ],
    )..listen(watched, (_, _) {});
    return container;
  }

  setUp(() => repo = _MockRepository());

  testWidgets('desconectado no busca recorridos', (tester) async {
    final container = containerFor(CourierAvailability.offline, courierAvailableOrdersProvider);
    await tester.pump();
    await tester.pump(courierPollEvery * 3);
    expect(container.read(courierAvailableOrdersProvider).value, isEmpty);
    verifyNever(() => repo.available());
    container.dispose();
  });

  testWidgets('con una entrega en curso no busca recorridos', (tester) async {
    final container = containerFor(CourierAvailability.busy, courierAvailableOrdersProvider);
    await tester.pump();
    await tester.pump(courierPollEvery * 3);
    verifyNever(() => repo.available());
    container.dispose();
  });

  testWidgets('conectado y libre busca cada tanto, y no en segundo plano', (tester) async {
    final container = containerFor(CourierAvailability.available, courierAvailableOrdersProvider);
    await tester.pump();
    await tester.pump();
    verify(() => repo.available()).called(1);

    await tester.pump(courierPollEvery);
    await tester.pump();
    verify(() => repo.available()).called(1);

    (container.read(appForegroundProvider.notifier) as _Foreground).show(visible: false);
    await tester.pump(courierPollEvery * 3);
    verifyNever(() => repo.available());

    (container.read(appForegroundProvider.notifier) as _Foreground).show(visible: true);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    verify(() => repo.available()).called(1);
    container.dispose();
  });

  testWidgets('la entrega en curso se revisa sola mientras está conectado', (tester) async {
    final container = containerFor(CourierAvailability.busy, courierActiveDeliveryProvider);
    await tester.pump();
    await tester.pump();
    clearInteractions(repo);

    await tester.pump(courierPollEvery);
    await tester.pump();
    verify(() => repo.activeDeliveries()).called(1);
    container.dispose();
  });

  group('ubicación del repartidor', () {
    late _MockLocation location;

    ProviderContainer sharing({StaffOrder? delivery}) {
      location = _MockLocation();
      when(() => location.current(ask: any(named: 'ask'))).thenAnswer((_) async => LocationFix(_here));
      when(() => repo.me()).thenAnswer((_) async => Ok(_profile(CourierAvailability.busy)));
      when(() => repo.activeDeliveries()).thenAnswer((_) async => Ok([?delivery]));
      when(() => repo.reportLocation(any())).thenAnswer((_) async => const Ok(null));
      return ProviderContainer(
        overrides: [
          courierRepositoryProvider.overrideWithValue(repo),
          locationServiceProvider.overrideWithValue(location),
          appForegroundProvider.overrideWith(_Foreground.new),
        ],
      )..listen(courierLocationSharingProvider, (_, _) {});
    }

    setUpAll(() => registerFallbackValue(_here));

    testWidgets('con un pedido en curso la manda cada tanto; el permiso se pide una vez', (tester) async {
      final container = sharing(delivery: _delivery());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      verify(() => repo.reportLocation(_here)).called(1);
      verify(() => location.current()).called(1);

      await tester.pump(courierLocationEvery);
      await tester.pump();
      verify(() => repo.reportLocation(_here)).called(1);
      verify(() => location.current(ask: false)).called(1);

      (container.read(appForegroundProvider.notifier) as _Foreground).show(visible: false);
      await tester.pump(courierLocationEvery * 3);
      verifyNever(() => repo.reportLocation(any()));
      container.dispose();
    });

    testWidgets('sin pedido en curso no la manda', (tester) async {
      final container = sharing();
      await tester.pump();
      await tester.pump(courierLocationEvery * 2);
      verifyNever(() => repo.reportLocation(any()));
      verifyNever(() => location.current(ask: any(named: 'ask')));
      container.dispose();
    });
  });
}
