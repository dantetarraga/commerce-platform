import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/auth/infrastructure/models/auth_dtos.dart';

abstract interface class AuthRemoteDataSource {
  Future<OtpChallengeDto> requestCode(String phone);

  Future<OtpVerifyResponseDto> verifyCode({
    required String phone,
    required String code,
  });

  Future<AuthResponseDto> register({
    required String registrationToken,
    required String firstName,
    required String lastName,
  });

  Future<UserDto> me();

  /// `PATCH /users/me`; `email: null` lo borra.
  Future<UserDto> updateMe({required String firstName, required String lastName, String? email});

  Future<void> logout(String refreshToken);
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<OtpChallengeDto> requestCode(String phone) async {
    final data = await _api.post('/auth/otp/request', body: {'phone': phone});
    return OtpChallengeDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<OtpVerifyResponseDto> verifyCode({
    required String phone,
    required String code,
  }) async {
    final data = await _api.post(
      '/auth/otp/verify',
      body: {'phone': phone, 'code': code},
    );
    return OtpVerifyResponseDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseDto> register({
    required String registrationToken,
    required String firstName,
    required String lastName,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {
        'registrationToken': registrationToken,
        'firstName': firstName,
        'lastName': lastName,
      },
    );
    return AuthResponseDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<UserDto> me() async {
    final data = await _api.get('/users/me');
    return UserDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<UserDto> updateMe({required String firstName, required String lastName, String? email}) async {
    final data = await _api.patch('/users/me', body: {'firstName': firstName, 'lastName': lastName, 'email': email});
    return UserDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> logout(String refreshToken) =>
      _api.post('/auth/logout', body: {'refreshToken': refreshToken});
}
