import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simula el almacenamiento nativo, conservando valores crudos entre instancias.
class MockPreferences extends Mock implements SharedPreferencesAsync {
  MockPreferences() {
    when(() => getString(any())).thenAnswer(
      (call) async => values[call.positionalArguments[0]] as String?,
    );
    when(
      () => getBool(any()),
    ).thenAnswer((call) async => values[call.positionalArguments[0]] as bool?);
    when(() => setString(any(), any())).thenAnswer((call) async {
      values[call.positionalArguments[0]! as String] =
          call.positionalArguments[1]! as String;
    });
    when(() => setBool(any(), any())).thenAnswer((call) async {
      values[call.positionalArguments[0]! as String] =
          call.positionalArguments[1]! as bool;
    });
    when(() => remove(any())).thenAnswer((call) async {
      values.remove(call.positionalArguments[0]);
    });
  }

  final values = <String, Object>{};
}

class MockSecureStorage extends Mock implements FlutterSecureStorage {
  MockSecureStorage() {
    when(
      () => read(key: any(named: 'key')),
    ).thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(
      () => write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      values[call.namedArguments[#key]! as String] =
          call.namedArguments[#value]! as String;
    });
    when(() => delete(key: any(named: 'key'))).thenAnswer((call) async {
      values.remove(call.namedArguments[#key]);
    });
  }

  final values = <String, String>{};
}
