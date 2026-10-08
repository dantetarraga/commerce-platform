import 'dart:async';

import 'package:apamuy/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/storage_mocks.dart';

void main() {
  late MockSecureStorage backend;
  late TokenStorage storage;

  const legacy = {
    'chaski.accessToken': 'old-access',
    'chaski.refreshToken': 'old-refresh',
  };
  const current = {
    'apamuy.accessToken': 'new-access',
    'apamuy.refreshToken': 'new-refresh',
  };

  setUp(() {
    backend = MockSecureStorage();
    storage = TokenStorage(backend);
  });

  test(
    'migra el par completo y conserva la sesión al volver a abrir',
    () async {
      backend.values.addAll(legacy);
      const tokens = (accessToken: 'old-access', refreshToken: 'old-refresh');
      expect(await storage.read(), tokens);
      expect(backend.values, {
        'apamuy.accessToken': 'old-access',
        'apamuy.refreshToken': 'old-refresh',
      });
      expect(await TokenStorage(backend).read(), tokens);
    },
  );

  test('una sesión nueva prevalece y retira ambos tokens antiguos', () async {
    backend.values.addAll({...legacy, ...current});
    expect(await storage.read(), (
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    ));
    expect(backend.values, current);
  });

  for (final key in ['apamuy.accessToken', 'apamuy.refreshToken']) {
    test(
      'un par nuevo incompleto ($key) no se mezcla con la sesión anterior',
      () async {
        backend.values.addAll({...legacy, key: current[key]!});
        expect(await storage.read(), isNull);
      },
    );
  }

  test('un par antiguo incompleto no se convierte en una sesión', () async {
    backend.values['chaski.accessToken'] = 'old-access';
    expect(await storage.read(), isNull);
    expect(backend.values.containsKey('apamuy.accessToken'), isFalse);
  });

  test(
    'guardar una sesión elimina los tokens antiguos sin leerlos primero',
    () async {
      backend.values.addAll(legacy);
      await storage.save((
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      ));
      expect(backend.values, current);
    },
  );

  test('cerrar sesión antes de migrar borra las dos versiones', () async {
    backend.values.addAll({...legacy, ...current});
    await storage.clear();
    expect(backend.values, isEmpty);
    expect(await TokenStorage(backend).read(), isNull);
  });

  test('cerrar sesión mientras migra no restaura los tokens', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    backend.values.addAll(legacy);
    when(() => backend.read(key: 'chaski.accessToken')).thenAnswer((_) async {
      final value = backend.values['chaski.accessToken'];
      started.complete();
      await release.future;
      return value;
    });
    final reading = storage.read();
    await started.future;
    final clearing = storage.clear();
    release.complete();
    await reading;
    await clearing;
    expect(backend.values, isEmpty);
  });

  test(
    'una copia fallida conserva el par antiguo y permite reintentar',
    () async {
      backend.values.addAll(legacy);
      var fail = true;
      when(
        () => backend.write(
          key: 'apamuy.refreshToken',
          value: any(named: 'value'),
        ),
      ).thenAnswer((call) async {
        if (fail) {
          fail = false;
          throw Exception('No se pudo guardar.');
        }
        backend.values['apamuy.refreshToken'] =
            call.namedArguments[#value]! as String;
      });
      await expectLater(storage.read(), throwsException);
      expect(backend.values, legacy);
      expect(await storage.read(), (
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      ));
    },
  );
}
