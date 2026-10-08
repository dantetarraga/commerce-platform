import 'dart:convert';

import 'package:apamuy/core/storage/storage_operation_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Documentos JSON pequeños guardados en el dispositivo (bolsa, direcciones,
/// búsquedas recientes). No es para datos sensibles: eso va en `TokenStorage`.
abstract interface class LocalJsonStore {
  Future<Object?> read(String key);

  Future<void> write(String key, Object? value);

  Future<void> remove(String key);
}

class SharedPrefsJsonStore implements LocalJsonStore {
  SharedPrefsJsonStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  // Solo las claves existentes antes del cambio de marca necesitan migración.
  static const _legacyKeys = {
    'apamuy.addresses': 'chaski.addresses',
    'apamuy.addresses.owner': 'chaski.addresses.owner',
    'apamuy.cart': 'chaski.cart',
    'apamuy.checkout': 'chaski.checkout',
    'apamuy.favorites': 'chaski.favorites',
    'apamuy.partnerMode': 'chaski.partnerMode',
    'apamuy.recentSearches': 'chaski.recentSearches',
    'apamuy.themeMode': 'chaski.themeMode',
  };

  final SharedPreferencesAsync _prefs;
  final _operations = StorageOperationQueue();

  @override
  Future<Object?> read(String key) => _operations.run(() async {
    final current = await _prefs.getString(key);
    final legacyKey = _legacyKeys[key];
    final raw =
        current ??
        (legacyKey == null ? null : await _prefs.getString(legacyKey));
    if (raw == null) return null;
    final Object? value;
    try {
      value = jsonDecode(raw);
    } on FormatException {
      // Un documento corrupto no debe romper la app: se descarta.
      await _remove(key);
      return null;
    }
    // Primero copia, luego borra: si falla la escritura, el original se conserva.
    if (current == null) await _prefs.setString(key, raw);
    await _removeLegacy(key);
    return value;
  });

  @override
  Future<void> write(String key, Object? value) => _operations.run(() async {
    await _prefs.setString(key, jsonEncode(value));
    await _removeLegacy(key);
  });

  @override
  Future<void> remove(String key) => _operations.run(() => _remove(key));

  Future<void> _remove(String key) async {
    await _prefs.remove(key);
    await _removeLegacy(key);
  }

  Future<void> _removeLegacy(String key) async {
    if (_legacyKeys[key] case final legacyKey?) await _prefs.remove(legacyKey);
  }
}

/// En memoria: para tests.
class MemoryJsonStore implements LocalJsonStore {
  final Map<String, String> _data = {};

  @override
  Future<Object?> read(String key) async =>
      _data[key] == null ? null : jsonDecode(_data[key]!);

  @override
  Future<void> write(String key, Object? value) async =>
      _data[key] = jsonEncode(value);

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
