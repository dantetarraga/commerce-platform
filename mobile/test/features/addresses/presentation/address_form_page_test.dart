import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/presentation/providers/address_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAddressRepository extends Mock implements AddressRepository {}

Future<_MockAddressRepository> _pumpForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _MockAddressRepository();
  when(repository.load).thenAnswer((_) async => AddressBook.empty);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [addressRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(theme: AppTheme.light(), home: const AddressFormPage()),
    ),
  );
  await tester.pump();
  return repository;
}

AppButton _saveButton(WidgetTester tester) => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Guardar dirección'));

void main() {
  setUpAll(() => registerFallbackValue(AddressBook.empty));

  testWidgets('si guardar falla, el botón deja de cargar y avisa', (tester) async {
    final repository = await _pumpForm(tester);
    when(() => repository.save(any())).thenThrow(Exception('disco lleno'));

    await tester.enterText(find.byType(TextFormField).first, 'Jr. Tacna 214');
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
