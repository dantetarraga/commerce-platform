// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserDto', json, ($checkedConvert) {
      final val = UserDto(
        id: $checkedConvert('id', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String),
        firstName: $checkedConvert('firstName', (v) => v as String),
        lastName: $checkedConvert('lastName', (v) => v as String),
        roles: $checkedConvert(
          'roles',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        email: $checkedConvert('email', (v) => v as String?),
        avatarUrl: $checkedConvert('avatarUrl', (v) => v as String?),
      );
      return val;
    });

OtpChallengeDto _$OtpChallengeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpChallengeDto', json, ($checkedConvert) {
      final val = OtpChallengeDto(
        phone: $checkedConvert('phone', (v) => v as String),
        resendAfterSeconds: $checkedConvert(
          'resendAfterSeconds',
          (v) => (v as num).toInt(),
        ),
        codeLength: $checkedConvert('codeLength', (v) => (v as num).toInt()),
      );
      return val;
    });

OtpVerifyResponseDto _$OtpVerifyResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OtpVerifyResponseDto', json, ($checkedConvert) {
  final val = OtpVerifyResponseDto(
    status: $checkedConvert('status', (v) => v as String),
    user: $checkedConvert(
      'user',
      (v) => v == null ? null : UserDto.fromJson(v as Map<String, dynamic>),
    ),
    accessToken: $checkedConvert('accessToken', (v) => v as String?),
    refreshToken: $checkedConvert('refreshToken', (v) => v as String?),
    registrationToken: $checkedConvert(
      'registrationToken',
      (v) => v as String?,
    ),
  );
  return val;
});

AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthResponseDto', json, ($checkedConvert) {
      final val = AuthResponseDto(
        user: $checkedConvert(
          'user',
          (v) => UserDto.fromJson(v as Map<String, dynamic>),
        ),
        accessToken: $checkedConvert('accessToken', (v) => v as String),
        refreshToken: $checkedConvert('refreshToken', (v) => v as String),
      );
      return val;
    });
