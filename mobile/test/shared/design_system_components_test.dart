import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('la esquina de salida corta solo la inferior izquierda', () {
    final r = AppRadius.exit(16);
    expect(r.topLeft, const Radius.circular(16));
    expect(r.topRight, const Radius.circular(16));
    expect(r.bottomRight, const Radius.circular(16));
    expect(r.bottomLeft, const Radius.circular(5));
    expect(AppRadius.exit(10).bottomLeft, const Radius.circular(3));
    expect(AppRadius.exit(22, cut: 6).bottomLeft, const Radius.circular(6));
  });

  test('card es blanca en claro y raised en oscuro', () {
    expect(ApamuyColors.light.card, AppColors.blanco);
    expect(ApamuyColors.dark.card, ApamuyColors.dark.raised);
  });

  testWidgets('AppSearchBar escucha al controller nuevo si cambia', (tester) async {
    final first = TextEditingController();
    final second = TextEditingController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(_app(SizedBox(width: 320, child: AppSearchBar(controller: first))));
    await tester.pumpWidget(_app(SizedBox(width: 320, child: AppSearchBar(controller: second))));

    second.text = 'pan';
    await tester.pump();
    expect(find.byTooltip('Limpiar'), findsOneWidget);

    // El viejo ya no está conectado: cambiarlo no debe fallar ni reconstruir.
    first.text = 'caldo';
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AmountRow marca el descuento y el total', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountRow(label: 'Envío', amount: Money(0), freeLabel: 'Gratis'),
              AmountRow.discount(label: 'Cupón', amount: Money(300)),
              AmountRow.total(label: 'Total', amount: Money(2350)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('− S/ 3.00'), findsOneWidget);
    expect(find.text('S/ 23.50'), findsOneWidget);
  });

  testWidgets('AppInlineNotice.fromError usa copy humano sin conexión y ofrece reintentar', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _app(AppInlineNotice.fromError(const NetworkFailure(), onRetry: () => retried = true)),
    );
    expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('AppCircleButton mide 48 y se anuncia con su tooltip', (tester) async {
    await tester.pumpWidget(_app(AppCircleButton(icon: Icons.call_rounded, tooltip: 'Llamar', onPressed: () {})));
    expect(tester.getSize(find.byType(AppCircleButton)), const Size.square(AppSpacing.minTouch));
    expect(find.bySemanticsLabel('Llamar'), findsOneWidget);
  });

  testWidgets('AppButton.ink es tinta en claro', (tester) async {
    await tester.pumpWidget(_app(AppButton.ink(label: 'Listo para recoger', onPressed: () {})));
    final material = tester.widget<Material>(find.descendant(of: find.byType(AppButton), matching: find.byType(Material)).first);
    expect(material.color, AppColors.tinta);
  });

  testWidgets('AppSectionHeader con "Ver todo" llama a la acción', (tester) async {
    var opened = false;
    await tester.pumpWidget(_app(AppSectionHeader('Cerca de ti', subtitle: 'Abiertos ahora', onSeeAll: () => opened = true)));
    expect(find.text('Abiertos ahora'), findsOneWidget);
    await tester.tap(find.text('Ver todo'));
    expect(opened, isTrue);
  });
}
