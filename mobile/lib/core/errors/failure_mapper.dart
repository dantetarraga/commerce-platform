import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/result/result.dart';

Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    NetworkException() => const NetworkFailure(),
    ApiException(statusCode: 401) => const UnauthorizedFailure(),
    ApiException(statusCode: 404, :final message) => NotFoundFailure(message),
    ApiException(code: 'VALIDATION_ERROR', :final message, :final details) =>
      ValidationFailure(message, fieldErrors: _fieldErrors(details)),
    ApiException(statusCode: >= 500) => const ServerFailure(),
    ApiException(:final code, :final message, :final details) =>
      BusinessFailure(code, message, details: details),
    _ => const ServerFailure(),
  };
}

/// Ejecuta una llamada a un datasource y devuelve `Result` en vez de lanzar.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Result.ok(await call());
  } on AppException catch (e) {
    return Result.err(mapExceptionToFailure(e));
  } on Exception {
    // JSON inesperado u otro fallo al interpretar la respuesta.
    return const Result.err(ServerFailure());
  }
}

Map<String, String> _fieldErrors(Map<String, Object?>? details) {
  final fields = details?['fields'];
  if (fields is! Map) return const {};
  return fields.map((key, value) => MapEntry('$key', '$value'));
}
