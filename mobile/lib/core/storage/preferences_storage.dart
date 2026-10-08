import 'package:apamuy/core/storage/storage_operation_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias no sensibles del dispositivo.
class PreferencesStorage {
  PreferencesStorage([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _onboardingSeenKey = 'apamuy.onboardingSeen';
  static const _legacyOnboardingSeenKey = 'chaski.onboardingSeen';

  final SharedPreferencesAsync _prefs;
  final _operations = StorageOperationQueue();

  Future<bool> isOnboardingSeen() => _operations.run(() async {
    final current = await _prefs.getBool(_onboardingSeenKey);
    final seen = current ?? await _prefs.getBool(_legacyOnboardingSeenKey);
    if (seen == null) return false;
    if (current == null) await _prefs.setBool(_onboardingSeenKey, seen);
    await _prefs.remove(_legacyOnboardingSeenKey);
    return seen;
  });

  Future<void> markOnboardingSeen() => _operations.run(() async {
    await _prefs.setBool(_onboardingSeenKey, true);
    await _prefs.remove(_legacyOnboardingSeenKey);
  });
}
