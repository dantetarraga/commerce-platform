import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/presentation/providers/app_foreground_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CourierRepository {}

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
}
