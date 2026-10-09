import 'package:apamuy/apps/customer/router/app_router.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  testWidgets('eliminar la cuenta pide confirmación y cierra la sesión', (tester) async {
    final original = FlutterError.onError;
    // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
    FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : original?.call(d);
    addTearDown(() => FlutterError.onError = original);

    final container = await pumpApamuy(tester, signedIn: true);
    container.read(appRouterProvider).goNamed(ProfilePage.name);
    await settle(tester, frames: 30);

    await tester.scrollUntilVisible(find.text('Eliminar mi cuenta'), 200);
    await tester.tap(find.text('Eliminar mi cuenta'));
    await settle(tester);
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);

    // Cancelar no toca nada.
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    expect(container.read(authSessionProvider).value, isNotNull);

    await tester.tap(find.text('Eliminar mi cuenta'));
    await settle(tester);
    await tester.tap(find.text('Eliminar cuenta'));
    await settle(tester, frames: 60);

    expect(container.read(authSessionProvider).value, isNull);
    expect(currentPath(container), '/entrar');

    await unmountApamuy(tester, container);
  });
}
