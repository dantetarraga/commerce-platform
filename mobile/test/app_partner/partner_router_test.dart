import 'package:chaski/app_partner/router/partner_routes.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chaski/features/courier_deliveries/courier_deliveries.dart';
import 'package:chaski/features/merchant_orders/merchant_orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  Future<void> logIn(WidgetTester tester, String phone) async {
    await tester.enterText(find.byType(TextFormField), phone);
    await tester.tap(find.text('Enviarme el código'));
    await settle(tester);
    await tester.enterText(
      find.descendant(of: find.byType(AuthOtpField), matching: find.byType(TextField)),
      FakeAuthRemoteDataSource.demoCode,
    );
    await settle(tester);
  }

  testWidgets('sin sesión abre la entrada de socios', (tester) async {
    final container = await pumpPartner(tester);
    expect(currentPartnerPath(container), PartnerRoutePaths.login);
    expect(find.text('Entra a Chaski Socios'), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('un negocio entra al modo Negocio', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_owner_chaski_dorado');
    expect(currentPartnerPath(container), PartnerRoutePaths.merchantHome);
    expect(find.byType(MerchantHomePage), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('un repartidor entra al modo Repartidor', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_courier_luis');
    expect(currentPartnerPath(container), PartnerRoutePaths.courierHome);
    expect(find.byType(CourierHomePage), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('un cliente ve que no es socio y puede usar otro número', (tester) async {
    final container = await pumpPartner(tester, signedInAs: 'usr_demo_customer');
    expect(currentPartnerPath(container), PartnerRoutePaths.notPartner);
    expect(find.byType(NotPartnerPage), findsOneWidget);

    await tester.tap(find.text('Usar otro número'));
    await settle(tester);
    expect(currentPartnerPath(container), PartnerRoutePaths.login);
    await unmountChaski(tester, container);
  });

  testWidgets('un número sin cuenta no pasa al registro de cliente', (tester) async {
    final container = await pumpPartner(tester);
    await logIn(tester, '999888777');
    expect(currentPartnerPath(container), PartnerRoutePaths.notPartner);
    expect(find.byType(ProfileSetupPage), findsNothing);

    await tester.tap(find.text('Usar otro número'));
    await settle(tester);
    expect(currentPartnerPath(container), PartnerRoutePaths.login);
    await unmountChaski(tester, container);
  });

  testWidgets('el negocio del seed entra con su celular y el código', (tester) async {
    final container = await pumpPartner(tester);
    await logIn(tester, FakeAuthRemoteDataSource.demoMerchantPhone);
    expect(currentPartnerPath(container), PartnerRoutePaths.merchantHome);
    await unmountChaski(tester, container);
  });
}
