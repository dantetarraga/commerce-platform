import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

/// Celular peruano: 9 dígitos que empiezan con 9.
final class PhoneNumber extends Equatable {
  const PhoneNumber._(this.value);

  /// Para valores que ya vienen validados por el backend.
  factory PhoneNumber.trusted(String raw) => switch (create(raw)) {
    Valid(:final value) => value,
    Invalid(:final failure) => throw ArgumentError(failure),
  };

  static final _pattern = RegExp(r'^9\d{8}$');

  final String value;

  static Validated<PhoneNumber> create(String raw) {
    final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (digits.isEmpty) return const Invalid(EmptyValue());
    if (!_pattern.hasMatch(digits)) return const Invalid(InvalidPhone());
    return Valid(PhoneNumber._(digits));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
