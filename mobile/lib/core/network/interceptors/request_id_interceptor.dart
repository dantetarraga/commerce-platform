import 'dart:math';

import 'package:dio/dio.dart';

/// Agrega `X-Request-Id` para correlacionar logs de la app con los del backend.
class RequestIdInterceptor extends Interceptor {
  final _random = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('X-Request-Id', _generateId);
    handler.next(options);
  }

  String _generateId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
