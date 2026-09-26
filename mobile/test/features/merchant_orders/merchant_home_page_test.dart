import 'package:chaski/app_partner/router/partner_routes.dart';
import 'package:chaski/features/merchant_orders/merchant_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  const merchant = 'usr_owner_chaski_dorado';

  testWidgets('un pedido nuevo suena hasta aceptarlo y pasa a preparación', (tester) async {
    final alarm = RecordingAlarm();
    final container = await pumpPartner(tester, signedInAs: merchant, alarm: alarm);
    expect(find.byType(MerchantHomePage), findsOneWidget);
    expect(find.text('Nuevos (1)'), findsOneWidget);
    expect(alarm.ringing, isTrue);
    expect(alarm.awake, isTrue);
    expect(find.text('“Sin ají, por favor”'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    await settle(tester);
    await tester.tap(find.text('30 min'));
    await settle(tester);
    await tester.tap(find.text('Aceptar · 30 min'));
    await settle(tester);

    expect(find.text('Nuevos'), findsOneWidget);
    expect(find.text('Preparando (2)'), findsOneWidget);
    expect(alarm.ringing, isFalse);
    await unmountChaski(tester, container);
  });

  testWidgets('rechazar exige un motivo y avisa al cliente', (tester) async {
    final container = await pumpPartner(tester, signedInAs: merchant);
    await tester.tap(find.text('Rechazar'));
    await settle(tester);

    // Sin motivo no se puede rechazar: la hoja sigue abierta.
    await tester.tap(find.text('Rechazar pedido'));
    await settle(tester);
    expect(find.text('¿Por qué lo rechazas?'), findsOneWidget);

    await tester.tap(find.text('Cocina llena'));
    await settle(tester);
    await tester.tap(find.text('Rechazar pedido'));
    await settle(tester);

    expect(find.text('Nuevos'), findsOneWidget);
    expect(find.text('Sin pedidos nuevos'), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('marcar listo lo pasa a la pestaña de listos', (tester) async {
    final container = await pumpPartner(tester, signedInAs: merchant);
    await tester.tap(find.text('Preparando (1)'));
    await settle(tester);
    await tester.tap(find.text('Marcar listo'));
    await settle(tester);
    expect(find.text('Listos (2)'), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('marca un producto agotado desde la lista de productos', (tester) async {
    final container = await pumpPartner(tester, signedInAs: merchant);
    await tester.tap(find.byTooltip('Productos'));
    await settle(tester);
    expect(currentPartnerPath(container), startsWith(PartnerRoutePaths.merchantHome));
    expect(find.byType(MerchantProductsPage), findsOneWidget);

    final soldOutBefore = find.text('Agotado').evaluate().length;
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(find.text('Agotado'), findsNWidgets(soldOutBefore + 1));
    await unmountChaski(tester, container);
  });
}
