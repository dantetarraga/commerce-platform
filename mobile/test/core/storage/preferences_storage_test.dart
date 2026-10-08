import 'package:apamuy/core/storage/preferences_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/storage_mocks.dart';

void main() {
  late MockPreferences prefs;
  late PreferencesStorage storage;

  setUp(() {
    prefs = MockPreferences();
    storage = PreferencesStorage(prefs);
  });

  for (final seen in [true, false]) {
    test('conserva onboardingSeen=$seen al migrar', () async {
      prefs.values['chaski.onboardingSeen'] = seen;
      expect(await storage.isOnboardingSeen(), seen);
      expect(prefs.values, {'apamuy.onboardingSeen': seen});
      expect(await PreferencesStorage(prefs).isOnboardingSeen(), seen);
    });
  }

  test('el valor false nuevo prevalece sobre el true antiguo', () async {
    prefs.values.addAll({
      'apamuy.onboardingSeen': false,
      'chaski.onboardingSeen': true,
    });
    expect(await storage.isOnboardingSeen(), isFalse);
    expect(prefs.values, {'apamuy.onboardingSeen': false});
  });

  test(
    'una instalación nueva muestra el onboarding hasta completarlo',
    () async {
      expect(await storage.isOnboardingSeen(), isFalse);
      await storage.markOnboardingSeen();
      expect(await storage.isOnboardingSeen(), isTrue);
    },
  );

  test(
    'completar el onboarding durante la lectura prevalece sobre el valor antiguo',
    () async {
      prefs.values['chaski.onboardingSeen'] = false;
      final reading = storage.isOnboardingSeen();
      final marking = storage.markOnboardingSeen();
      await reading;
      await marking;
      expect(await storage.isOnboardingSeen(), isTrue);
      expect(prefs.values, {'apamuy.onboardingSeen': true});
    },
  );
}
