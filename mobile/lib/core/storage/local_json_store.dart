import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Documentos JSON pequeños guardados en el dispositivo (bolsa, direcciones,
/// búsquedas recientes). No es para datos sensibles: eso va en `TokenStorage`.
abstract interface class LocalJsonStore {
  Future<Object?> read(String key);

  Future<void> write(String key, Object? value);

  Future<void> remove(String key);
}

class SharedPrefsJsonStore implements LocalJsonStore {
  SharedPrefsJsonStore([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<Object?> read(String key) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      // Un documento corrupto no debe romper la app: se descarta.
      await _prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? value) => _prefs.setString(key, jsonEncode(value));

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// En memoria: para tests.
class MemoryJsonStore implements LocalJsonStore {
  final Map<String, String> _data = {};

  @override
  Future<Object?> read(String key) async => _data[key] == null ? null : jsonDecode(_data[key]!);

  @override
  Future<void> write(String key, Object? value) async => _data[key] = jsonEncode(value);

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
