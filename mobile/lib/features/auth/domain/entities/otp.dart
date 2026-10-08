import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:equatable/equatable.dart';

/// Código enviado: a qué número, de cuántos dígitos y cuándo se puede reenviar.
final class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.phone,
    required this.resendAfter,
    this.codeLength = 6,
  });

  final PhoneNumber phone;
  final Duration resendAfter;
  final int codeLength;

  @override
  List<Object?> get props => [phone, resendAfter, codeLength];
}

/// Resultado de verificar el código.
sealed class OtpVerification extends Equatable {
  const OtpVerification();
}

/// El número ya tenía cuenta: sesión iniciada.
final class OtpSignedIn extends OtpVerification {
  const OtpSignedIn(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class OtpProfileRequired extends OtpVerification {
  const OtpProfileRequired({
    required this.phone,
    required this.registrationToken,
  });

  final PhoneNumber phone;
  final String registrationToken;

  @override
  List<Object?> get props => [phone, registrationToken];
}
