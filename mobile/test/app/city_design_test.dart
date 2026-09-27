import 'package:chaski/core/maps/delivery_map_data.dart';
import 'package:chaski/features/onboarding/presentation/widgets/city_onboarding_scene.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/design_capture.dart';

class _MapAdapter implements DeliveryMapAdapter {
  DeliveryMapData? received;

  @override
  Widget build(BuildContext context, DeliveryMapData data) {
    received = data;
    return const Text('Proveedor de mapa conectado');
  }
}

void main() {
  setUpAll(loadDesignFonts);

  for (final (name, size, scale, brightness) in [
    ('inicio', const Size(390, 844), 1.0, Brightness.light),
    ('inicio_oscuro', const Size(390, 844), 1.0, Brightness.dark),
    ('inicio_compacto', const Size(320, 720), 1.4, Brightness.light),
    ('inicio_tablet', const Size(768, 1024), 1.0, Brightness.light),
  ]) {
    testWidgets('ciudad: navegación y composición $name', (tester) async {
      final container = await pumpChaski(tester, signedIn: true, size: size, textScale: scale, brightness: brightness, disableAnimations: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settle(tester);
      expect(find.textContaining('al toque.', findRichText: true), findsOneWidget);
      expect(find.byType(AppNavigationDock), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureCity(tester, name);
      await tester.tap(find.byTooltip('Buscar').last);
      await settle(tester);
      expect(find.byType(TextField), findsWidgets);
      if (name == 'inicio') await captureCity(tester, 'explorar');
      await tester.tap(find.byTooltip('Inicio'));
      await settle(tester);
      await tester.scrollUntilVisible(find.text('Recomendados para ti'), 160, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -150));
      await settle(tester);
      if (name == 'inicio') await captureCity(tester, 'descubrir');
      expect(tester.takeException(), isNull);
      await unmountChaski(tester, container);
      await tester.pump(const Duration(seconds: 12));
    });
  }

  testWidgets('el onboarding responde al swipe y permite volver', (tester) async {
    final container = await pumpChaski(tester, onboardingSeen: false, disableAnimations: true);
    await captureCity(tester, 'onboarding_descubre');
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await settle(tester);
    expect(find.text('Tu antojo tiene\nbuenas manos.'), findsOneWidget);
    await captureCity(tester, 'onboarding_elige');
    await tester.tap(find.text('Siguiente').hitTestable().first);
    await settle(tester);
    await captureCity(tester, 'onboarding_recibe');
    expect(find.text('Empezar a pedir'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await settle(tester);
    expect(find.text('Tu antojo tiene\nbuenas manos.'), findsOneWidget);
    await unmountChaski(tester, container);
  });

  testWidgets('la ilustración del onboarding sigue al dedo y encaja en una estación', (tester) async {
    final container = await pumpChaski(tester, onboardingSeen: false);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(CityOnboardingScene)));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    final page = tester.widget<CityOnboardingScene>(find.byType(CityOnboardingScene)).page;
    expect(page, greaterThan(0));
    expect(page, lessThan(1));
    await gesture.up();
    await settle(tester);
    final settled = tester.widget<CityOnboardingScene>(find.byType(CityOnboardingScene)).page;
    expect(settled, settled.roundToDouble());
    await unmountChaski(tester, container);
  });

  testWidgets('el mapa entrega coordenadas al adaptador sin tipos de un SDK', (tester) async {
    final adapter = _MapAdapter();
    const data = DeliveryMapData(estimatedProgress: 0.4, store: MapCoordinate(-14.79, -71.41), destination: MapCoordinate(-14.8, -71.4));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deliveryMapAdapterProvider.overrideWithValue(adapter)],
        child: const MaterialApp(
          home: Scaffold(body: DeliveryMap(data: data)),
        ),
      ),
    );
    expect(find.text('Proveedor de mapa conectado'), findsOneWidget);
    expect(adapter.received, same(data));
  });
}
