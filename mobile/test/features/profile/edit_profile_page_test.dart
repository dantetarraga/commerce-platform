import 'package:apamuy/app/router/app_router.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  testWidgets('edita nombre y correo desde Tú', (tester) async {
    final original = FlutterError.onError;
    // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
    FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : original?.call(d);
    addTearDown(() => FlutterError.onError = original);

    final container = await pumpApamuy(tester, signedIn: true);
    container.read(appRouterProvider).goNamed(ProfilePage.name);
    await settle(tester, frames: 30);

    await tester.tap(find.byTooltip('Editar tus datos'));
    await settle(tester, frames: 30);
    expect(find.text('Tus datos'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(2), 'no-es-correo');
    await tester.tap(find.text('Guardar'));
    await settle(tester);
    expect(find.text('Este campo es obligatorio.'), findsOneWidget);
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);

    await tester.enterText(fields.at(0), '  Alexandra  ');
    await tester.enterText(fields.at(2), 'Alex@Correo.pe');
    await tester.tap(find.text('Guardar'));
    await settle(tester, frames: 60);

    final user = container.read(authSessionProvider).value!;
    expect(user.firstName, 'Alexandra');
    expect(user.email?.value, 'alex@correo.pe');
    expect(find.text('Tus datos'), findsNothing);
    expect(find.text('Alexandra Quispe'), findsOneWidget);

    await unmountApamuy(tester, container);
  });
}
