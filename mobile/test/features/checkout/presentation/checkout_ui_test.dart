import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/cart/domain/repositories/cart_repository.dart';
import 'package:apamuy/features/cart/presentation/providers/cart_providers.dart';
import 'package:apamuy/features/cart/presentation/widgets/cart_sheet.dart';
import 'package:apamuy/features/checkout/checkout.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/domain/delivery_slots.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:apamuy/features/checkout/presentation/providers/delivery_slots_provider.dart';
import 'package:apamuy/features/checkout/presentation/widgets/payment_sheet.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
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

class _FixedSlots implements DeliverySlotsRepository {
  const _FixedSlots(this.days);

  final List<DeliveryDay> days;

  @override
  Future<Result<List<DeliveryDay>>> forStore(String storeId) async => Ok(days);
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) builder, {
  Cart? cart,
  ThemeData? theme,
  List<DeliveryDay> slots = const [],
}) async {
  // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
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
      cartRepositoryProvider.overrideWithValue(_MemoryCartRepository(cart ?? Cart.empty)),
      deliverySlotsRepositoryProvider.overrideWithValue(_FixedSlots(slots)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(body: Builder(builder: (context) => Center(child: builder(context)))),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('Programar ofrece solo las horas del negocio y guarda la elegida', (tester) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final tomorrow = day.add(const Duration(days: 1));
    final dinner = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19);
    final container = await _pump(
      tester,
      (context) => TextButton(
        onPressed: () => showScheduleSheet(context, storeId: 's1', storeName: 'Pizzería Qori'),
        child: const Text('abrir'),
      ),
      slots: [
        DeliveryDay(date: day, slots: const []),
        DeliveryDay(date: tomorrow, slots: [dinner, dinner.add(const Duration(minutes: 15))]),
      ],
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Para cuándo?'), findsOneWidget);
    // Hoy no atiende: arranca en mañana, con sus horas.
    expect(find.text('Hoy · Cerrado'), findsOneWidget);
    expect(find.text('7:00 pm', findRichText: true), findsOneWidget);
    expect(find.text('7:15 pm', findRichText: true), findsOneWidget);
    await tester.tap(find.text('7:15 pm', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Programar para mañana'));
    await tester.pumpAndSettle();
    expect(container.read(scheduledDeliveryProvider), dinner.add(const Duration(minutes: 15)));
  });

  testWidgets('La hoja de pago elige efectivo con vuelto', (tester) async {
    final container = await _pump(
      tester,
      (context) => TextButton(onPressed: () => showPaymentSheet(context, total: const Money(4140)), child: const Text('abrir')),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo pagas?'), findsOneWidget);
    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S/ 50.00'));
    await tester.pumpAndSettle();
    expect(find.text('Te llevamos S/ 8.60 de vuelto.'), findsOneWidget);
    await tester.tap(find.text('Usar efectivo'));
    await tester.pumpAndSettle();
    final draft = container.read(checkoutControllerProvider).draft;
    expect(draft.paymentKind, PaymentKind.cash);
    expect(draft.cashChangeFor, const Money(5000));
  });

  for (final (name, theme) in [('claro', AppTheme.light()), ('oscuro', AppTheme.dark())]) {
    testWidgets('La boleta se arma sin errores ($name) y la propina suma al total', (tester) async {
      final cart = Cart(store: _store, lines: [_line('a', 'Chairo espinarense', 1740), _line('b', 'Rocoto relleno', 2200)]);
      final container = await _pump(tester, (_) => const CheckoutPage(), cart: cart, theme: theme);
      await tester.pumpAndSettle();
      expect(find.text('Tu boleta'), findsOneWidget);
      expect(find.text('Elige dónde te lo llevamos.'), findsOneWidget);
      // total = 39.40 + 3.00 de envío
      expect(find.text('S/ 42.40'), findsWidgets);
      await tester.tap(find.text('S/ 2'));
      await tester.pumpAndSettle();
      expect(container.read(checkoutControllerProvider).draft.tip, const Money(200));
      expect(find.text('S/ 44.40'), findsWidgets);
      // Tocarla otra vez la quita.
      await tester.tap(find.text('S/ 2'));
      await tester.pumpAndSettle();
      expect(container.read(checkoutControllerProvider).draft.tip, const Money.zero());
    });
  }

  testWidgets('La bolsa anima filas, avisa el mínimo y guarda la nota', (tester) async {
    final cart = Cart(store: _store, lines: [_line('a', 'Mate de coca', 400), _line('b', 'Pan chuta', 300)]);
    final container = await _pump(
      tester,
      (_) => SizedBox(height: 700, child: CartSheet(onCheckout: () {}, onExplore: () {})),
      cart: cart,
    );
    await container.read(cartControllerProvider.future);
    await tester.pumpAndSettle();
    expect(find.text('Tu bolsa'), findsOneWidget);
    expect(find.textContaining('para el pedido mínimo'), findsOneWidget);
    // Quitar una línea (en 1, el "−" es quitar) y verla salir.
    await tester.tap(find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(find.text('Mate de coca'), findsNothing);
    expect(find.text('Pan chuta'), findsOneWidget);
    await tester.tap(find.byTooltip('Agregar uno'));
    await tester.pumpAndSettle();
    expect(container.read(cartControllerProvider).value!.itemCount, 2);
    await container.read(cartControllerProvider.notifier).setNote('tocar el timbre');
    await tester.pumpAndSettle();
    expect(find.text('“tocar el timbre”'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5)); // cierra el aviso de deshacer
  });
}
