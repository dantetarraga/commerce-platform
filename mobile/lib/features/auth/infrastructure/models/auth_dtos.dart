import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

@JsonSerializable()
class UserDto {
  const UserDto({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.email,
    this.avatarUrl,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String? email;
  final String? avatarUrl;
  final List<String> roles;
}

/// Respuesta de `POST /auth/otp/request`.
@JsonSerializable()
class OtpChallengeDto {
  const OtpChallengeDto({required this.phone, required this.resendAfterSeconds, required this.codeLength});

  factory OtpChallengeDto.fromJson(Map<String, dynamic> json) => _$OtpChallengeDtoFromJson(json);

  final String phone;
  final int resendAfterSeconds;
  final int codeLength;
}

/// Respuesta de `POST /auth/otp/verify`.
///
/// - `status: AUTHENTICATED` → `user`, `accessToken`, `refreshToken`.
/// - `status: PROFILE_REQUIRED` → `registrationToken`.
@JsonSerializable()
class OtpVerifyResponseDto {
  const OtpVerifyResponseDto({
    required this.status,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.registrationToken,
  });

  factory OtpVerifyResponseDto.fromJson(Map<String, dynamic> json) => _$OtpVerifyResponseDtoFromJson(json);

  static const authenticated = 'AUTHENTICATED';
  static const profileRequired = 'PROFILE_REQUIRED';

  final String status;
  final UserDto? user;
  final String? accessToken;
  final String? refreshToken;
  final String? registrationToken;
}

/// Respuesta de `POST /auth/register` (sesión ya iniciada).
@JsonSerializable()
class AuthResponseDto {
  const AuthResponseDto({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => _$AuthResponseDtoFromJson(json);

  final UserDto user;
  final String accessToken;
  final String refreshToken;
}
