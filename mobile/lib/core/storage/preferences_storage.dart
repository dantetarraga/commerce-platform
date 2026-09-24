import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias no sensibles del dispositivo.
class PreferencesStorage {
  PreferencesStorage([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _onboardingSeenKey = 'chaski.onboardingSeen';

  final SharedPreferencesAsync _prefs;

  Future<bool> isOnboardingSeen() async =>
      await _prefs.getBool(_onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() => _prefs.setBool(_onboardingSeenKey, true);
}
