import 'dart:convert';
import 'dart:typed_data';

import 'package:apamuy/core/network/interceptors/auth_interceptor.dart';
import 'package:apamuy/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokens extends TokenStorage {
  _MemoryTokens(this.tokens);

  StoredTokens? tokens;

  @override
  Future<StoredTokens?> read() async => tokens;

  @override
  Future<void> save(StoredTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

/// Responde según la ruta con lo que diga [routes]; cuenta las llamadas.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.routes);

  final Map<String, ResponseBody Function(RequestOptions)> routes;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    final route = routes[options.path];
    if (route == null) throw StateError('Ruta inesperada ${options.path}');
    return route(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// 401 con el token viejo; con el nuevo, lo que diga [then].
ResponseBody Function(RequestOptions) _expiredThen(ResponseBody Function() then) =>
    (o) => o.headers['Authorization'] == 'Bearer a1' ? _json(401, {'code': 'UNAUTHORIZED'}) : then();

void main() {
  late _MemoryTokens tokens;
  late Dio dio;
  late _ScriptedAdapter adapter;
  late int expired;

  void setUpDio(Map<String, ResponseBody Function(RequestOptions)> routes) {
    adapter = _ScriptedAdapter(routes);
    final options = BaseOptions(baseUrl: 'http://test');
    dio = Dio(options)..httpClientAdapter = adapter;
    final refreshDio = Dio(options)..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(refreshDio: refreshDio, tokenStorage: tokens, onSessionExpired: () => expired++),
    );
  }

  setUp(() {
    tokens = _MemoryTokens((accessToken: 'a1', refreshToken: 'r1'));
    expired = 0;
  });

  final refreshed = {
    '/auth/refresh': (_) => _json(200, {'accessToken': 'a2', 'refreshToken': 'r2'}),
  };

  test('ante un 401 renueva una vez y reintenta con el token nuevo', () async {
    setUpDio({
      ...refreshed,
      '/orders': _expiredThen(() => _json(200, {'ok': true})),
    });

    final response = await dio.get<Map<String, dynamic>>('/orders');

    expect(response.data, {'ok': true});
    expect(tokens.tokens, (accessToken: 'a2', refreshToken: 'r2'));
    expect(adapter.calls, ['/orders', '/auth/refresh', '/orders']);
  });

  test('si el reintento también falla, el error llega y la app no se cuelga', () async {
    setUpDio({
      ...refreshed,
      '/courier/orders/o1/accept': _expiredThen(() => _json(409, {'code': 'ORDER_ALREADY_TAKEN'})),
      '/me': (_) => _json(200, {'id': 'u1'}),
    });

    await expectLater(
      dio.post<void>('/courier/orders/o1/accept').timeout(const Duration(seconds: 2)),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 409)),
    );
    // La cola de errores sigue libre para lo que venga después.
    final after = await dio.get<Map<String, dynamic>>('/me').timeout(const Duration(seconds: 2));
    expect(after.data, {'id': 'u1'});
  });

  test('sin señal al renovar no cierra la sesión', () async {
    setUpDio({
      '/auth/refresh': (o) => throw DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: o,
      ),
      '/orders': _expiredThen(() => _json(200, {})),
    });

    await expectLater(dio.get<void>('/orders'), throwsA(isA<DioException>()));
    expect(tokens.tokens, isNotNull);
    expect(expired, 0);
  });

  test('un refresh token rechazado sí cierra la sesión', () async {
    setUpDio({
      '/auth/refresh': (_) => _json(401, {'code': 'INVALID_REFRESH_TOKEN'}),
      '/orders': _expiredThen(() => _json(200, {})),
    });

    await expectLater(dio.get<void>('/orders'), throwsA(isA<DioException>()));
    expect(tokens.tokens, isNull);
    expect(expired, 1);
  });
}
