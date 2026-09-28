import 'package:chaski/core/domain/email_address.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/features/auth/domain/entities/auth_user.dart';
import 'package:chaski/features/auth/domain/entities/otp.dart';
import 'package:chaski/features/auth/infrastructure/models/auth_dtos.dart';

extension UserDtoMapper on UserDto {
  AuthUser toDomain() => AuthUser(
    id: id,
    phone: PhoneNumber.trusted(phone),
    firstName: firstName,
    lastName: lastName,
    email: email == null ? null : EmailAddress.trusted(email!),
    avatarUrl: avatarUrl,
    roles: roles.map(_roleFromApi).nonNulls.toSet(),
  );
}

extension OtpChallengeDtoMapper on OtpChallengeDto {
  OtpChallenge toDomain() => OtpChallenge(
    phone: PhoneNumber.trusted(phone),
    resendAfter: Duration(seconds: resendAfterSeconds),
    codeLength: codeLength,
  );
}

UserRole? _roleFromApi(String role) => switch (role) {
  'CUSTOMER' => UserRole.customer,
  'MERCHANT' => UserRole.merchant,
  'COURIER' => UserRole.courier,
  'ADMIN' => UserRole.admin,
  _ => null,
};
