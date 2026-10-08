import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(overrides: [fakeBackendProvider.overrideWithValue(FakeBackend(latency: Duration.zero))]);
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('la página agrupa por día y marca todo como leído', (tester) async {
    final c = container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.light(), home: const NotificationsPage()),
      ),
    );
    // El nudo del pedido en curso late sin parar: se avanza el reloj a mano.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Los avisos del pedido van en EN CURSO; HOY/AYER dependen de la hora del reloj.
    expect(find.text('EN CURSO'), findsOneWidget);
    expect(find.text('AYER'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Sin leer. Pedido en curso')), findsOneWidget);
    expect(find.text('Luis está a la vuelta 👀'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Sin leer')), findsWidgets);

    await tester.tap(find.text('Marcar leídos'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel(RegExp('^Sin leer')), findsNothing);
  });

  testWidgets('el filtro Ofertas deja solo las promociones', (tester) async {
    final c = container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.light(), home: const NotificationsPage()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Ofertas'));
    // La pestaña nueva es otra consulta al backend.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('EN CURSO'), findsNothing);
    expect(find.text('Luis está a la vuelta 👀'), findsNothing);
    expect(find.text('2x1 en café de altura hasta las 5'), findsOneWidget);
  });
}
