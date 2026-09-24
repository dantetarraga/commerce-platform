import 'package:equatable/equatable.dart';

/// Errores que la capa de presentación entiende. Nunca exponen Dio ni HTTP.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión. Revisa tu internet e inténtalo de nuevo.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Tu sesión expiró. Vuelve a iniciar sesión.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontramos lo que buscabas.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Regla de negocio rechazada por el backend (p. ej. `CART_STORE_CONFLICT`).
final class BusinessFailure extends Failure {
  const BusinessFailure(this.code, super.message, {this.details});

  final String code;
  final Map<String, Object?>? details;

  @override
  List<Object?> get props => [code, message, details];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Algo salió mal de nuestro lado. Inténtalo en unos minutos.']);
}
