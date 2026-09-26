import 'package:chaski/features/courier_deliveries/courier_deliveries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  const courier = 'usr_courier_luis';

  testWidgets('desconectado no ve pedidos; al conectarse suenan los listos', (tester) async {
    final alarm = RecordingAlarm();
    final container = await pumpPartner(tester, signedInAs: courier, alarm: alarm);
    expect(find.byType(CourierHomePage), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);
    expect(find.text('Tomar pedido'), findsNothing);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Conectado'), findsOneWidget);
    expect(find.text('Tomar pedido'), findsNWidgets(2));
    expect(alarm.rings, 1);
    expect(alarm.awake, isTrue);
    await unmountChaski(tester, container);
  });

  testWidgets('toma un pedido, lo recoge y lo entrega registrando el cobro', (tester) async {
    final container = await pumpPartner(tester, signedInAs: courier, size: const Size(390, 1000));
    await tester.tap(find.byType(Switch));
    await settle(tester);

    await tester.tap(find.text('Tomar pedido').first);
    await settle(tester);
    expect(find.byType(ActiveDeliveryPage), findsOneWidget);
    expect(find.text('Cobrar al entregar'), findsOneWidget);

    await tester.tap(find.text('Lo recogí'));
    await settle(tester);
    await tester.tap(find.text('Entregado'));
    await settle(tester);
    expect(find.text('Monto recibido (S/)'), findsOneWidget);

    await tester.tap(find.text('Confirmar entrega'));
    await settle(tester);
    expect(find.byType(ActiveDeliveryPage), findsNothing);
    expect(find.textContaining('2 entregas'), findsOneWidget);
    await unmountChaski(tester, container);
  });
}
