import 'package:apamuy/features/courier_deliveries/domain/location_sharing.dart';
import 'package:apamuy/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:apamuy/features/courier_deliveries/presentation/widgets/location_sharing_notice.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sharing extends CourierLocationSharing {
  _Sharing(this._status);

  final CourierLocationStatus _status;
  int fixes = 0;

  @override
  CourierLocationStatus build() => _status;

  @override
  Future<void> fix() async => fixes++;
}

void main() {
  Future<_Sharing> pump(WidgetTester tester, CourierLocationStatus status) async {
    final sharing = _Sharing(status);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [courierLocationSharingProvider.overrideWith(() => sharing)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: LocationSharingNotice()),
        ),
      ),
    );
    return sharing;
  }

  testWidgets('compartiendo no muestra nada', (tester) async {
    await pump(tester, CourierLocationStatus.sharing);
    expect(find.byType(AppInlineNotice), findsNothing);
  });

  testWidgets('sin permiso explica por qué y lo vuelve a pedir', (tester) async {
    final sharing = await pump(tester, CourierLocationStatus.denied);
    expect(find.textContaining('el cliente no te ve llegar'), findsOneWidget);
    await tester.tap(find.text('Permitir ubicación'));
    expect(sharing.fixes, 1);
  });

  testWidgets('bloqueado lleva a los ajustes', (tester) async {
    await pump(tester, CourierLocationStatus.blocked);
    expect(find.text('Abrir ajustes'), findsOneWidget);
  });
}
