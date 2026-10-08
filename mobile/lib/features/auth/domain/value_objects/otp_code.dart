import 'package:apamuy/core/domain/validated.dart';
import 'package:apamuy/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

/// Código de verificación: exactamente [length] dígitos.
final class OtpCode extends Equatable {
  const OtpCode._(this.value);

  static const length = 6;
  static final _pattern = RegExp(r'^\d{6}$');

  final String value;

  static Validated<OtpCode> create(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return const Invalid(EmptyValue());
    if (!_pattern.hasMatch(digits)) return const Invalid(InvalidOtp());
    return Valid(OtpCode._(digits));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
