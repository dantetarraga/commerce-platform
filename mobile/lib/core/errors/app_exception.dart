/// Excepciones internas de la capa infrastructure. Los datasources (reales o
/// fake) las lanzan y los repositorios las convierten a `Failure`.
sealed class AppException implements Exception {
  const AppException();
}

/// Respuesta de error del backend con el formato estándar de la API.
final class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, Object?>? details;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

final class NetworkException extends AppException {
  const NetworkException();
}

/// La respuesta llegó pero no se pudo interpretar (JSON inesperado, etc.).
final class UnexpectedException extends AppException {
  const UnexpectedException(this.cause);

  final Object cause;

  @override
  String toString() => 'UnexpectedException($cause)';
}
