import 'package:equatable/equatable.dart';

/// Motivo por el que un value object rechazó un valor crudo.
sealed class ValueFailure extends Equatable {
  const ValueFailure();

  @override
  List<Object?> get props => [];
}

final class EmptyValue extends ValueFailure {
  const EmptyValue();
}

final class InvalidEmail extends ValueFailure {
  const InvalidEmail();
}

final class InvalidPhone extends ValueFailure {
  const InvalidPhone();
}

final class TooShort extends ValueFailure {
  const TooShort(this.min);
  final int min;

  @override
  List<Object?> get props => [min];
}

final class TooLong extends ValueFailure {
  const TooLong(this.max);
  final int max;

  @override
  List<Object?> get props => [max];
}

/// Código de verificación con formato inválido.
final class InvalidOtp extends ValueFailure {
  const InvalidOtp();
}

final class OutOfRange extends ValueFailure {
  const OutOfRange(this.min, this.max);
  final num min;
  final num max;

  @override
  List<Object?> get props => [min, max];
}
