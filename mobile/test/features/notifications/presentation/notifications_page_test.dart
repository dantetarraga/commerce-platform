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
    await tester.pumpAndSettle();

    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('Luis está a la vuelta 👀'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Sin leer')), findsWidgets);

    await tester.tap(find.text('Marcar leídos'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^Sin leer')), findsNothing);
  });
}
