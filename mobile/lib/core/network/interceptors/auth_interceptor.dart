import 'package:apamuy/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Agrega el Bearer token y, ante un 401, refresca una sola vez y reintenta.
/// Sin loops: es `QueuedInterceptor`, el refresh y el reintento usan `_refreshDio`
/// (sin interceptores), cada request se reintenta una vez (`extra['retried']`) y
/// `/auth/*` nunca refresca.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio refreshDio,
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
  }) : _refreshDio = refreshDio,
       _tokenStorage = tokenStorage,
       _onSessionExpired = onSessionExpired;

  static const _retriedKey = 'retried';

  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthPath(options.path)) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !_isAuthPath(request.path);
    if (!shouldRefresh) return handler.next(err);

    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      _onSessionExpired();
      return handler.next(err);
    }

    try {
      // Si otra request ya refrescó mientras esta esperaba en la cola,
      // el token guardado es distinto al usado: se reintenta sin refrescar.
      final usedHeader = request.headers['Authorization'];
      final accessToken = usedHeader == 'Bearer ${tokens.accessToken}'
          ? await _refresh(tokens.refreshToken)
          : tokens.accessToken;

      request
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra[_retriedKey] = true;
      // No con `_dio`: su error esperaría en esta misma cola, detrás de este
      // handler que lo espera a él, y la app entera quedaría colgada.
      handler.resolve(await _refreshDio.fetch<dynamic>(request));
    } on DioException catch (refreshError) {
      if (refreshError.requestOptions.path.endsWith('/auth/refresh')) {
        // Solo un rechazo del backend cierra la sesión. Sin señal o con un 5xx
        // se conserva y la pantalla ofrece reintentar.
        if (_rejected(refreshError)) {
          await _tokenStorage.clear();
          _onSessionExpired();
          return handler.next(err);
        }
        return handler.next(refreshError);
      }
      handler.next(refreshError);
    }
  }

  Future<String> _refresh(String refreshToken) async {
    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data!;
    final tokens = (
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _tokenStorage.save(tokens);
    return tokens.accessToken;
  }

  bool _isAuthPath(String path) => path.startsWith('/auth/');

  /// Token vencido, revocado o cuenta desactivada.
  static bool _rejected(DioException e) => switch (e.response?.statusCode) {
    401 || 403 => true,
    _ => false,
  };
}
