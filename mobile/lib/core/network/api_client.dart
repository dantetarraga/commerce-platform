import 'package:chaski/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

/// Envoltura mínima sobre Dio: devuelve el `data` decodificado y convierte
/// cualquier `DioException` en `AppException`, así Dio no sale de infrastructure.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) =>
      _send(() => _dio.post<dynamic>(path, data: body, options: Options(headers: headers)));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw convertDioException(e);
    }
  }
}

AppException convertDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final response = e.response;
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return ApiException(
          statusCode: response?.statusCode ?? 500,
          code: data['code'] as String? ?? 'UNKNOWN_ERROR',
          message: data['message'] as String? ?? 'Error inesperado',
          details: data['details'] as Map<String, Object?>?,
        );
      }
      return ApiException(
        statusCode: response?.statusCode ?? 500,
        code: 'UNKNOWN_ERROR',
        message: 'Error inesperado',
      );
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return UnexpectedException(e.error ?? e);
  }
}
