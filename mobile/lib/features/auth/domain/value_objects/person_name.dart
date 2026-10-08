import 'package:apamuy/core/domain/validated.dart';
import 'package:apamuy/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

final class PersonName extends Equatable {
  const PersonName._(this.value);

  static const maxLength = 60;

  final String value;

  static Validated<PersonName> create(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return const Invalid(EmptyValue());
    if (trimmed.length > maxLength) return const Invalid(TooLong(maxLength));
    return Valid(PersonName._(trimmed));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
