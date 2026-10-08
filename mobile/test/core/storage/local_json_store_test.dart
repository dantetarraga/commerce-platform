import 'dart:async';
import 'dart:convert';

import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/storage_mocks.dart';

void main() {
  late MockPreferences prefs;
  late SharedPrefsJsonStore store;

  setUp(() {
    prefs = MockPreferences();
    store = SharedPrefsJsonStore(prefs);
  });

  test(
    'migra los ocho documentos de Chaski y persisten al volver a abrir',
    () async {
      const documents = <String, Object>{
        'addresses': [
          {'id': 'casa', 'street': 'Jr. Lima 123'},
        ],
        'addresses.owner': 'cliente-1',
        'cart': {
          'lines': [
            {'productId': 'p1', 'quantity': 2},
          ],
        },
        'checkout': {'tip': 200},
        'favorites': {
          'stores': ['s1'],
          'products': ['p1'],
        },
        'partnerMode': 'merchant',
        'recentSearches': ['pollo', 'pan'],
        'themeMode': 'dark',
      };
      for (final entry in documents.entries) {
        prefs.values['chaski.${entry.key}'] = jsonEncode(entry.value);
      }

      for (final entry in documents.entries) {
        expect(await store.read('apamuy.${entry.key}'), entry.value);
        expect(prefs.values.containsKey('chaski.${entry.key}'), isFalse);
      }
      final reopened = SharedPrefsJsonStore(prefs);
      for (final entry in documents.entries) {
        expect(await reopened.read('apamuy.${entry.key}'), entry.value);
      }
    },
  );

  test('el valor nuevo prevalece y elimina la copia antigua', () async {
    prefs.values.addAll({
      'apamuy.cart': '{"lines":[]}',
      'chaski.cart': '{"lines":[1]}',
    });
    expect(await store.read('apamuy.cart'), {'lines': <Object>[]});
    expect(prefs.values.containsKey('chaski.cart'), isFalse);
  });

  test(
    'un null guardado con la clave nueva no recupera datos antiguos',
    () async {
      prefs.values.addAll({
        'apamuy.checkout': 'null',
        'chaski.checkout': '{"tip":200}',
      });
      expect(await store.read('apamuy.checkout'), isNull);
      expect(prefs.values, {'apamuy.checkout': 'null'});
    },
  );

  for (final corruptKey in ['chaski.cart', 'apamuy.cart']) {
    test(
      'descarta JSON corrupto en $corruptKey sin restaurar datos obsoletos',
      () async {
        prefs.values['chaski.cart'] = '{"lines":[1]}';
        prefs.values[corruptKey] = '{invalido';
        expect(await store.read('apamuy.cart'), isNull);
        expect(prefs.values, isEmpty);
        expect(await store.read('apamuy.cart'), isNull);
      },
    );
  }

  test(
    'escribir o borrar antes de leer también retira el valor antiguo',
    () async {
      prefs.values.addAll({'chaski.cart': '[1]', 'chaski.favorites': '[2]'});
      await store.write('apamuy.cart', <Object>[]);
      await store.remove('apamuy.favorites');
      expect(prefs.values, {'apamuy.cart': '[]'});
      expect(await store.read('apamuy.favorites'), isNull);
    },
  );

  test('borrar durante una migración no resucita el carrito', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    prefs.values['chaski.cart'] = '[1]';
    when(() => prefs.getString('chaski.cart')).thenAnswer((_) async {
      final value = prefs.values['chaski.cart']! as String;
      started.complete();
      await release.future;
      return value;
    });
    final reading = store.read('apamuy.cart');
    await started.future;
    final deleting = store.remove('apamuy.cart');
    release.complete();
    await reading;
    await deleting;
    expect(prefs.values, isEmpty);
  });

  test(
    'una escritura durante la migración conserva el valor más reciente',
    () async {
      prefs.values['chaski.themeMode'] = '"dark"';
      final reading = store.read('apamuy.themeMode');
      final writing = store.write('apamuy.themeMode', 'light');
      await reading;
      await writing;
      expect(await store.read('apamuy.themeMode'), 'light');
      expect(prefs.values.containsKey('chaski.themeMode'), isFalse);
    },
  );

  test(
    'un fallo al copiar conserva el original y permite reintentar',
    () async {
      prefs.values['chaski.favorites'] = '[1]';
      var fail = true;
      when(() => prefs.setString('apamuy.favorites', any())).thenAnswer((
        call,
      ) async {
        if (fail) {
          fail = false;
          throw Exception('No se pudo guardar.');
        }
        prefs.values['apamuy.favorites'] =
            call.positionalArguments[1]! as String;
      });
      await expectLater(store.read('apamuy.favorites'), throwsException);
      expect(prefs.values, {'chaski.favorites': '[1]'});
      expect(await store.read('apamuy.favorites'), [1]);
      expect(prefs.values, {'apamuy.favorites': '[1]'});
    },
  );

  test(
    'las claves ajenas a la migración mantienen su comportamiento',
    () async {
      await store.write('otro.documento', {'ok': true});
      expect(await store.read('otro.documento'), {'ok': true});
      await store.remove('otro.documento');
      expect(await store.read('otro.documento'), isNull);
    },
  );
}
