import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

final class EmailAddress extends Equatable {
  const EmailAddress._(this.value);

  /// Para valores que ya vienen validados por el backend.
  factory EmailAddress.trusted(String raw) => switch (create(raw)) {
    Valid(:final value) => value,
    Invalid(:final failure) => throw ArgumentError(failure),
  };

  static final _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  final String value;

  /// Normaliza (trim + minúsculas) y valida.
  static Validated<EmailAddress> create(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return const Invalid(EmptyValue());
    if (!_pattern.hasMatch(normalized)) return const Invalid(InvalidEmail());
    return Valid(EmailAddress._(normalized));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
