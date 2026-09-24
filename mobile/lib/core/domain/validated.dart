import 'package:chaski/core/domain/value_failure.dart';

/// Resultado de construir un value object: el valor válido o el motivo del rechazo.
sealed class Validated<T> {
  const Validated();

  bool get isValid => this is Valid<T>;

  ValueFailure? get failureOrNull => switch (this) {
    Valid() => null,
    Invalid(:final failure) => failure,
  };

  T? get valueOrNull => switch (this) {
    Valid(:final value) => value,
    Invalid() => null,
  };
}

final class Valid<T> extends Validated<T> {
  const Valid(this.value);
  final T value;
}

final class Invalid<T> extends Validated<T> {
  const Invalid(this.failure);
  final ValueFailure failure;
}
