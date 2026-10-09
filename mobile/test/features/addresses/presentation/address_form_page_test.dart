import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/geocoding_service.dart';
import 'package:apamuy/features/addresses/addresses.dart';
import 'package:apamuy/features/addresses/domain/address.dart';
import 'package:apamuy/features/addresses/presentation/providers/address_providers.dart';
import 'package:apamuy/features/addresses/presentation/widgets/neighborhood_plan.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAddressRepository extends Mock implements AddressRepository {}

class _MockGeocodingService extends Mock implements GeocodingService {}

Future<_MockAddressRepository> _pumpForm(WidgetTester tester, {GeocodingService geocoding = const NoGeocodingService()}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _MockAddressRepository();
  when(repository.load).thenAnswer((_) async => AddressBook.empty);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addressRepositoryProvider.overrideWithValue(repository),
        geocodingServiceProvider.overrideWithValue(geocoding),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AddressFormPage()),
    ),
  );
  await tester.pump();
  return repository;
}

AppButton _saveButton(WidgetTester tester) => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Guardar dirección'));

void main() {
  setUpAll(() {
    registerFallbackValue(AddressBook.empty);
    registerFallbackValue(GeoCoordinates.trusted(0, 0));
  });

  testWidgets('si guardar falla, el botón deja de cargar y avisa', (tester) async {
    final repository = await _pumpForm(tester);
    when(() => repository.save(any())).thenThrow(Exception('disco lleno'));

    await tester.enterText(find.byType(TextFormField).first, 'Jr. Tacna 214');
    await tester.enterText(find.byType(TextFormField).at(1), 'Puerta verde');
    await tester.tap(find.text('Guardar dirección'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    verify(() => repository.save(any())).called(1);
    expect(_saveButton(tester).loading, isFalse);
    expect(find.text('No pudimos guardar la dirección. Inténtalo otra vez.'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('mover el mapa llena la calle, pero no pisa lo que escribió el usuario', (tester) async {
    final geocoding = _MockGeocodingService();
    when(() => geocoding.streetAt(any())).thenAnswer((_) async => 'Jr. Bolognesi 305');
    when(() => geocoding.find(any(), within: any(named: 'within'))).thenAnswer((_) async => null);
    await _pumpForm(tester, geocoding: geocoding);
    final street = find.byType(TextFormField).first;

    await tester.drag(find.byType(NeighborhoodPlan), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(find.descendant(of: street, matching: find.text('Jr. Bolognesi 305')), findsOneWidget);

    await tester.enterText(street, 'Av. Garcilaso 120');
    await tester.pump(const Duration(seconds: 1));
    verify(() => geocoding.find('Av. Garcilaso 120', within: any(named: 'within'))).called(1);
    await tester.drag(find.byType(NeighborhoodPlan), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(find.descendant(of: street, matching: find.text('Av. Garcilaso 120')), findsOneWidget);
  });

  testWidgets('pide una referencia para el repartidor', (tester) async {
    final repository = await _pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Jr. Tacna 214');
    await tester.tap(find.text('Guardar dirección'));
    await tester.pump();

    expect(find.text('Cuéntale al repartidor cómo reconocer tu puerta.'), findsOneWidget);
    verifyNever(() => repository.save(any()));
  });

  testWidgets('no guarda un punto fuera de la zona de reparto', (tester) async {
    final repository = await _pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Jr. Tacna 214');
    await tester.enterText(find.byType(TextFormField).at(1), 'Puerta verde');
    await tester.pumpAndSettle();
    // El plano dibujado corre ~1 m por px: 9000 px son unos 9 km.
    for (var i = 0; i < 30; i++) {
      await tester.drag(find.byType(NeighborhoodPlan), const Offset(0, 300));
    }
    await tester.pumpAndSettle();
    expect(find.text('Fuera de la zona de reparto'), findsOneWidget);

    await tester.tap(find.text('Guardar dirección'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Ese punto está fuera de la zona de reparto de Yauri.'), findsOneWidget);
    verifyNever(() => repository.save(any()));
    AppToast.dismiss();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('"Otro" pide un nombre', (tester) async {
    final repository = await _pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Jr. Tacna 214');
    await tester.tap(find.text('Otro'));
    await tester.pump();
    await tester.tap(find.text('Guardar dirección'));
    await tester.pump();

    expect(find.text('Ponle un nombre para reconocerla.'), findsOneWidget);
    verifyNever(() => repository.save(any()));
  });
}
