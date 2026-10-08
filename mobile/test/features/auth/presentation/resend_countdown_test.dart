import 'package:apamuy/features/auth/presentation/widgets/resend_countdown.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, DateTime? canResendAt, {VoidCallback? onResend}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: ResendCountdown(canResendAt: canResendAt, onResend: onResend)),
  ),
);

void main() {
  testWidgets('cuenta en m:ss y al llegar a cero ofrece reenviar', (tester) async {
    var resent = 0;
    await _pump(tester, DateTime.now().add(const Duration(seconds: 65)), onResend: () => resent++);
    expect(find.textContaining('1:05'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('1:04'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.textContaining('0:58'), findsOneWidget);

    await tester.pump(const Duration(seconds: 58));
    await tester.pumpAndSettle();
    expect(find.text('Reenviar código'), findsOneWidget);
    await tester.tap(find.text('Reenviar código'));
    expect(resent, 1);
    // Si el timer siguiera vivo, el test fallaría por temporizadores pendientes.
  });

  testWidgets('un código nuevo reinicia la cuenta', (tester) async {
    await _pump(tester, null);
    expect(find.text('Reenviar código'), findsOneWidget);

    await _pump(tester, DateTime.now().add(const Duration(seconds: 30)));
    await tester.pumpAndSettle();
    expect(find.textContaining('0:30'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });
}
