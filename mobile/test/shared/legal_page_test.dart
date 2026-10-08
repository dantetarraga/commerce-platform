import 'package:apamuy/app/router/app_router.dart';
import 'package:apamuy/shared/legal/legal_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('los términos se leen sin sesión y enlazan a la privacidad', (tester) async {
    final original = FlutterError.onError;
    // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
    FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : original?.call(d);
    addTearDown(() => FlutterError.onError = original);

    final container = await pumpApamuy(tester);
    await settle(tester, frames: 30);

    expect(find.textContaining('Al continuar aceptas', findRichText: true), findsOneWidget);
    _tapSpan(tester, 'términos');
    await settle(tester, frames: 30);
    expect(find.text('Términos y condiciones'), findsOneWidget);
    expect(find.textContaining('el negocio vende y prepara'), findsOneWidget);

    await tester.tapOnText(find.textRange.ofSubstring('Política de privacidad'));
    await settle(tester, frames: 30);
    expect(find.text(LegalDocument.privacy.title), findsOneWidget);
    final matches = container.read(appRouterProvider).routerDelegate.currentConfiguration.matches;
    expect(matches.map((m) => m.matchedLocation), ['/entrar', '/legal/terminos', '/legal/privacidad']);

    await unmountApamuy(tester, container);
  });
}

/// Toca el tramo [text] de un Text.rich (su TapGestureRecognizer).
void _tapSpan(WidgetTester tester, String text) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    var tapped = false;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == text && span.recognizer is TapGestureRecognizer) {
        (span.recognizer! as TapGestureRecognizer).onTap!();
        tapped = true;
        return false;
      }
      return true;
    });
    if (tapped) return;
  }
  fail('No hay un enlace "$text"');
}
