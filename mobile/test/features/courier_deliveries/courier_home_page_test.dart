import 'package:apamuy/features/courier_deliveries/courier_deliveries.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/app_harness.dart';

void main() {
  const courier = 'usr_courier_luis';

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

  testWidgets('desconectado no ve pedidos; al conectarse suenan los listos', (tester) async {
    final alarm = RecordingAlarm();
    final container = await pumpPartner(tester, signedInAs: courier, alarm: alarm);
    expect(find.byType(CourierHomePage), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);
    expect(find.text('Tomar recorrido'), findsNothing);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('En ruta · conectado'), findsOneWidget);
    expect(find.text('Tomar recorrido'), findsWidgets);
    expect(alarm.rings, 1);
    expect(alarm.awake, isTrue);
    await unmountApamuy(tester, container);
  });

  testWidgets('toma un pedido, lo recoge y lo entrega registrando el cobro', (tester) async {
    final container = await pumpPartner(tester, signedInAs: courier, size: const Size(390, 1000));
    // El pedido histórico del demo puede pertenecer a ayer cerca de medianoche.
    final before = tester.widget<Text>(find.textContaining(RegExp(r'^\d+ entrega'))).data!;
    final deliveredBefore = int.parse(before.split(' ').first);
    await tester.tap(find.byType(Switch));
    await settle(tester);

    await tester.ensureVisible(find.text('Tomar recorrido').first);
    await tester.tap(find.text('Tomar recorrido').first);
    await settle(tester);
    expect(find.byType(ActiveDeliveryPage), findsOneWidget);
    expect(find.text('COBRA AL ENTREGAR'), findsOneWidget);

    await tester.drag(find.text('Lo recogí'), const Offset(600, 0));
    await settle(tester);
    await tester.drag(find.text('Entregado'), const Offset(600, 0));
    await settle(tester);
    expect(find.text('Monto recibido (S/)'), findsOneWidget);

    await tester.tap(find.text('Confirmar entrega'));
    await settle(tester);
    expect(find.byType(ActiveDeliveryPage), findsNothing);
    expect(find.text('Entregado. ¡Buen trabajo!'), findsOneWidget);
    expect(find.byType(AppRiveSuccess), findsOneWidget);
    for (var i = 0; i < 50 && find.byType(rive.RiveArtboardWidget).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.byType(rive.RiveArtboardWidget), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    if (const bool.fromEnvironment('CAPTURE_RIVE')) {
      await expectLater(find.byType(Overlay).first, matchesGoldenFile('../../../../docs/ui/rive/socios_entrega.png'));
    }
    await tester.scrollUntilVisible(find.text('Tu jornada de hoy'), 350, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    expect(find.textContaining('${deliveredBefore + 1} entrega'), findsOneWidget);
    await unmountApamuy(tester, container);
  });
}
