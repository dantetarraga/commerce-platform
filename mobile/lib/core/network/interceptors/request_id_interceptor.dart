import 'package:chaski/core/utils/random_id.dart';
import 'package:dio/dio.dart';

/// Agrega `X-Request-Id` para correlacionar logs de la app con los del backend.
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('X-Request-Id', randomHexId);
    handler.next(options);
  }
}
