import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/checkout/presentation/widgets/knot_celebration.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

final _order = Order(
  id: 'demo',
  code: '#3105',
  store: const OrderStore(id: 'tienda', name: 'Picantería Doña Rosa', ownerName: 'Rosa'),
  lines: const [OrderLine(name: 'Chairo espinarense', quantity: 2, total: Money(3000))],
  subtotal: const Money(3000),
  deliveryFee: const Money(300),
  discount: const Money.zero(),
  total: const Money(3300),
  addressTitle: 'Casa',
  addressStreet: 'Jr. Tacna 214',
  payment: const YapePayment(),
  status: OrderStatus.received,
  events: const [],
  placedAt: DateTime(2026, 9, 26, 12),
);

void main() {
  setUpAll(() async {
    expect(await rive.RiveNative.init(), isTrue);
    for (final (family, asset) in [
      ('Jakarta', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
      ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final (name, size, scale, reduced, dark) in [
    ('claro', const Size(390, 844), 1.0, false, false),
    ('oscuro', const Size(390, 844), 1.0, false, true),
    ('texto_grande', const Size(320, 720), 1.4, true, false),
  ]) {
    testWidgets('pedido enviado: Rive y seguimiento en $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      OrderConfirmedAction? action;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => action = await showOrderConfirmed(context, order: _order),
                child: const Text('Confirmar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final track = find.widgetWithText(AppButton, 'Seguir mi pedido');
      expect(tester.widget<AppButton>(track).onPressed, isNotNull);
      if (!reduced) {
        for (var i = 0; i < 50 && find.byType(rive.RiveArtboardWidget).evaluate().isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump();
        }
        expect(find.byType(rive.RiveArtboardWidget), findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('¡Pedido enviado!'), findsOneWidget);
      expect(find.textContaining('Sigue aquí su confirmación'), findsOneWidget);
      expect(find.textContaining('ya lo vio'), findsNothing);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_RIVE')) {
        await expectLater(find.byType(Scaffold).last, matchesGoldenFile('../../../../../docs/ui/rive/pedido_$name.png'));
      }
      await tester.tap(track);
      await tester.pumpAndSettle();
      expect(action, OrderConfirmedAction.track);
    });
  }

  testWidgets('volver a Cerca devuelve la acción de inicio', (tester) async {
    OrderConfirmedAction? action;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(data: const MediaQueryData(disableAnimations: true), child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => action = await showOrderConfirmed(context, order: _order),
              child: const Text('Confirmar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a Cerca'));
    await tester.pumpAndSettle();
    expect(action, OrderConfirmedAction.home);
  });
}
