import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/cart/domain/repositories/cart_repository.dart';
import 'package:chaski/features/cart/presentation/providers/cart_providers.dart';
import 'package:chaski/features/cart/presentation/widgets/cart_sheet.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCartRepository implements CartRepository {
  _MemoryCartRepository(this.cart);

  Cart cart;

  @override
  Future<Cart> load() async => cart;

  @override
  Future<void> save(Cart next) async => cart = next;

  @override
  Future<Result<Coupon>> validateCoupon({required String code, required String storeId, required Money subtotal}) async =>
      const Ok(Coupon(code: 'ESPINAR', discount: Money(300), label: 'S/ 3'));
}

const _store = CartStore(id: 's1', name: 'Picantería Doña Rosa', deliveryFee: Money(300), minOrderAmount: Money(1000), etaMinutes: 25);

CartLine _line(String id, String name, int price) =>
    CartLine(id: id, productId: 'p_$id', name: name, unitPrice: Money(price), quantity: Quantity.one);

Future<ProviderContainer> _pumpSheet(WidgetTester tester, Cart cart) async {
  final original = FlutterError.onError;
  FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : original?.call(d);
  addTearDown(() => FlutterError.onError = original);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      localJsonStoreProvider.overrideWithValue(MemoryJsonStore()),
      cartRepositoryProvider.overrideWithValue(_MemoryCartRepository(cart)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SizedBox(height: 700, child: CartSheet(onCheckout: () {}, onExplore: () {}))),
      ),
    ),
  );
  await container.read(cartControllerProvider.future);
  await tester.pumpAndSettle();
  return container;
}

/// Avanza lo justo para las animaciones de salida sin que el aviso (4 s)
/// alcance a cerrarse, como haría `pumpAndSettle`.
Future<void> _pumpBriefly(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Quitar con "−" muestra "Deshacer" y lo devuelve a su lugar', (tester) async {
    final container = await _pumpSheet(tester, Cart(store: _store, lines: [_line('a', 'Mate de coca', 400), _line('b', 'Pan chuta', 300)]));

    await tester.tap(find.byTooltip('Quitar').first);
    await _pumpBriefly(tester);
    expect(find.text('Mate de coca'), findsNothing);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await _pumpBriefly(tester);
    final lines = container.read(cartControllerProvider).value!.lines;
    expect(lines.map((l) => l.id), ['a', 'b']);
    expect(find.text('Mate de coca'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('Deslizar la última línea deja la bolsa vacía y "Deshacer" la recupera', (tester) async {
    final container = await _pumpSheet(tester, Cart(store: _store, lines: [_line('a', 'Chairo espinarense', 1740)]));

    await tester.drag(find.text('Chairo espinarense'), const Offset(-500, 0));
    await _pumpBriefly(tester);
    expect(find.text('Tu bolsa está vacía'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await _pumpBriefly(tester);
    expect(container.read(cartControllerProvider).value!.lines.single.id, 'a');
    expect(find.text('Chairo espinarense'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });
}
