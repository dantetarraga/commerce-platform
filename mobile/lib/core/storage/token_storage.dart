import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef StoredTokens = ({String accessToken, String refreshToken});

/// Guarda access y refresh token en el almacenamiento seguro del sistema.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'chaski.accessToken';
  static const _refreshKey = 'chaski.refreshToken';

  final FlutterSecureStorage _storage;

  Future<StoredTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  Future<void> save(StoredTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
