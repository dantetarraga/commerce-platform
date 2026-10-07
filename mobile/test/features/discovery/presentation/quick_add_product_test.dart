import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';
import 'package:chaski/features/stores/presentation/providers/stores_providers.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStores extends Mock implements StoresRepository {}

const _product = ProductHit(id: 'pr_mate', name: 'Mate de coca', price: Money(300), storeId: 'st_1', storeName: 'Doña Rosa');

StoreSummary _store({bool open = true}) => StoreSummary(
  id: 'st_1',
  name: 'Doña Rosa',
  categoryIds: const [],
  rating: const StoreRating(average: 4.8, count: 10),
  distanceKm: 1,
  etaMinutes: 25,
  deliveryFee: const Money(300),
  minOrderAmount: const Money(0),
  isOpenNow: open,
  deliversToYou: true,
);

void main() {
  late _MockStores stores;

  setUp(() => stores = _MockStores());
  tearDown(AppToast.dismiss);

  Future<bool?> tapQuickAdd(WidgetTester tester, {StoreSummary? known}) async {
    bool? added;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storesRepositoryProvider.overrideWithValue(stores)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => added = await quickAddProduct(context, ref, _product, known: known),
              child: const Text('+'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('+'));
    // Sin pumpAndSettle: el aviso se cerraría solo antes de buscarlo.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return added;
  }

  testWidgets('si no carga el negocio, avisa el error en vez de lanzar', (tester) async {
    when(() => stores.getStoreDetail('st_1', near: any(named: 'near'))).thenAnswer((_) async => const Result.err(NetworkFailure()));

    expect(await tapQuickAdd(tester), isFalse);
    expect(find.text(AppInlineNotice.messageFor(const NetworkFailure())), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('con el negocio cerrado no agrega y dice por qué', (tester) async {
    when(() => stores.getStoreDetail('st_1', near: any(named: 'near'))).thenAnswer(
      (_) async => Result.ok(StoreDetail(summary: _store(open: false), addressLine: 'Jr. Tacna', schedule: const WeeklySchedule([]))),
    );

    expect(await tapQuickAdd(tester), isFalse);
    expect(find.text(cannotOrderMessage(_store(open: false))), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('con el negocio ya conocido no lo vuelve a pedir', (tester) async {
    expect(await tapQuickAdd(tester, known: _store(open: false)), isFalse);
    verifyNever(() => stores.getStoreDetail(any(), near: any(named: 'near')));
    await tester.pump(const Duration(seconds: 5));
  });
}
