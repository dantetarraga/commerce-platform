import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:apamuy/features/auth/domain/entities/otp.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';

abstract interface class AuthRepository {
  Future<Result<OtpChallenge>> requestCode(PhoneNumber phone);

  /// Verifica el código: inicia sesión o pide completar el perfil.
  Future<Result<OtpVerification>> verifyCode(PhoneNumber phone, OtpCode code);

  /// Crea la cuenta de un número ya verificado.
  Future<Result<AuthUser>> completeProfile({
    required String registrationToken,
    required PersonName firstName,
    required PersonName lastName,
  });

  /// Cambia nombre y correo de la cuenta; `email: null` lo borra.
  Future<Result<AuthUser>> updateProfile({
    required PersonName firstName,
    required PersonName lastName,
    EmailAddress? email,
  });

  /// Devuelve el usuario si hay una sesión guardada y válida, o `null`.
  Future<Result<AuthUser?>> restoreSession();

  /// Cierra la sesión localmente aunque el backend no responda.
  Future<void> logout();
}
