import 'package:chaski/core/domain/value_failure.dart';

/// Mensajes en español para los rechazos de value objects (usado en formularios).
extension ValueFailureMessage on ValueFailure {
  String get message => switch (this) {
    EmptyValue() => 'Este campo es obligatorio.',
    InvalidEmail() => 'Ingresa un correo válido.',
    InvalidPhone() => 'Ingresa un celular de 9 dígitos que empiece con 9.',
    TooShort(:final min) => 'Debe tener al menos $min caracteres.',
    TooLong(:final max) => 'Debe tener como máximo $max caracteres.',
    InvalidOtp() => 'El código tiene 6 dígitos.',
    OutOfRange(:final min, :final max) => 'Debe estar entre $min y $max.',
  };
}
