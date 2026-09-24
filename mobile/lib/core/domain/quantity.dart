import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

/// Cantidad de un producto en una línea de pedido (1..99).
final class Quantity extends Equatable {
  const Quantity._(this.value);

  static const min = 1;
  static const max = 99;
  static const one = Quantity._(1);

  final int value;

  static Validated<Quantity> create(int value) {
    if (value < min || value > max) return const Invalid(OutOfRange(min, max));
    return Valid(Quantity._(value));
  }

  bool get canIncrement => value < max;
  bool get canDecrement => value > min;

  Quantity increment() => canIncrement ? Quantity._(value + 1) : this;
  Quantity decrement() => canDecrement ? Quantity._(value - 1) : this;

  @override
  List<Object?> get props => [value];
}
