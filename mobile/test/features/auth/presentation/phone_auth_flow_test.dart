import 'package:chaski/app/router/routes.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';

void main() {
  Future<void> enterPhone(WidgetTester tester, String phone) async {
    await tester.enterText(find.byType(TextFormField), phone);
    await tester.tap(find.text('Enviarme el código'));
    await settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.descendant(of: find.byType(AuthOtpField), matching: find.byType(TextField)), code);
    await settle(tester);
  }

  testWidgets('sin sesión abre la entrada con celular', (tester) async {
    final container = await pumpChaski(tester);
    expect(currentPath(container), RoutePaths.login);
    expect(find.text('¿Cuál es tu celular?'), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('valida el celular antes de pedir el código', (tester) async {
    final container = await pumpChaski(tester);
    await enterPhone(tester, '12345');
    expect(find.text('Ingresa un celular de 9 dígitos que empiece con 9.'), findsOneWidget);
    expect(find.byType(OtpPage), findsNothing);
    await unmountChaski(tester, container);
  });

  testWidgets('un número con cuenta entra directo tras el código', (tester) async {
    final container = await pumpChaski(tester);
    await enterPhone(tester, '984123456');
    expect(find.byType(OtpPage), findsOneWidget);
    expect(find.textContaining('984 123 456'), findsOneWidget);

    await enterCode(tester, '123456');

    expect(currentPath(container), RoutePaths.home);
    expect(container.read(authSessionProvider).value?.firstName, 'Alex');
    await unmountChaski(tester, container);
  });

  testWidgets('un código incorrecto muestra el error y permite reintentar', (tester) async {
    final container = await pumpChaski(tester);
    await enterPhone(tester, '984123456');
    await enterCode(tester, '000000');

    expect(find.textContaining('no coincide'), findsOneWidget);
    expect(currentPath(container), startsWith(RoutePaths.login));

    await enterCode(tester, '123456');
    expect(currentPath(container), RoutePaths.home);
    await unmountChaski(tester, container);
  });

  testWidgets('un número nuevo solo pide el nombre y entra', (tester) async {
    final container = await pumpChaski(tester);
    await enterPhone(tester, '987654321');
    await enterCode(tester, '123456');

    expect(find.byType(ProfileSetupPage), findsOneWidget);
    Finder field(String label) => find.descendant(of: find.widgetWithText(AppInput, label), matching: find.byType(TextFormField));
    await tester.enterText(field('Nombre'), 'Ana');
    await tester.enterText(field('Apellido'), 'Huamán');
    await tester.tap(find.text('Empezar a pedir'));
    await settle(tester);

    expect(currentPath(container), RoutePaths.home);
    expect(container.read(authSessionProvider).value?.fullName, 'Ana Huamán');
    await unmountChaski(tester, container);
  });
}
