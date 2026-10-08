import 'package:apamuy/core/storage/storage_operation_queue.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef StoredTokens = ({String accessToken, String refreshToken});

/// Guarda access y refresh token en el almacenamiento seguro del sistema.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'apamuy.accessToken';
  static const _refreshKey = 'apamuy.refreshToken';
  static const _legacyAccessKey = 'chaski.accessToken';
  static const _legacyRefreshKey = 'chaski.refreshToken';

  final FlutterSecureStorage _storage;
  final _operations = StorageOperationQueue();

  Future<StoredTokens?> read() => _operations.run(() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access != null || refresh != null) {
      // Nunca mezcla tokens nuevos con una sesión antigua o incompleta.
      if (access == null || refresh == null) return null;
      await _clearLegacy();
      return (accessToken: access, refreshToken: refresh);
    }
    final legacyAccess = await _storage.read(key: _legacyAccessKey);
    final legacyRefresh = await _storage.read(key: _legacyRefreshKey);
    if (legacyAccess == null || legacyRefresh == null) return null;
    final tokens = (accessToken: legacyAccess, refreshToken: legacyRefresh);
    try {
      await _write(tokens);
    } on Exception {
      // Si la copia queda a medias, conserva el par antiguo para reintentar.
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      rethrow;
    }
    await _clearLegacy();
    return tokens;
  });

  Future<void> save(StoredTokens tokens) =>
      _operations.run(() => _save(tokens));

  Future<void> _save(StoredTokens tokens) async {
    await _write(tokens);
    await _clearLegacy();
  }

  Future<void> _write(StoredTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() => _operations.run(() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _clearLegacy();
  });

  Future<void> _clearLegacy() async {
    await _storage.delete(key: _legacyAccessKey);
    await _storage.delete(key: _legacyRefreshKey);
  }
}
