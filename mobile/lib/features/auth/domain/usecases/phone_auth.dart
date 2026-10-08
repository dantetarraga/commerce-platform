import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:apamuy/features/auth/domain/entities/otp.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';

class RequestCode {
  const RequestCode(this._repository);

  final AuthRepository _repository;

  Future<Result<OtpChallenge>> call(PhoneNumber phone) => _repository.requestCode(phone);
}

class VerifyCode {
  const VerifyCode(this._repository);

  final AuthRepository _repository;

  Future<Result<OtpVerification>> call(PhoneNumber phone, OtpCode code) => _repository.verifyCode(phone, code);
}

class CompleteProfile {
  const CompleteProfile(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String registrationToken,
    required PersonName firstName,
    required PersonName lastName,
  }) => _repository.completeProfile(registrationToken: registrationToken, firstName: firstName, lastName: lastName);
}
