import 'package:chaski/features/addresses/presentation/widgets/neighborhood_plan.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arrastrar el plano avisa cuánto se movió', (tester) async {
    Offset? moved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: NeighborhoodPlan(seed: '', height: 300, hint: 'Mueve el mapa hasta tu puerta', onMoved: (o) => moved = o),
        ),
      ),
    );
    expect(find.text('Mueve el mapa hasta tu puerta'), findsOneWidget);

    await tester.drag(find.byType(NeighborhoodPlan), const Offset(60, -40));
    await tester.pumpAndSettle();
    expect(moved, isNotNull);
    expect(moved!.dx, greaterThan(0));
    expect(moved!.dy, lessThan(0));
  });
}
