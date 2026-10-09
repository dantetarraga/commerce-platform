import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/token_storage.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:apamuy/features/auth/domain/entities/otp.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'package:apamuy/features/auth/infrastructure/mappers/auth_mapper.dart';
import 'package:apamuy/features/auth/infrastructure/models/auth_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<OtpChallenge>> requestCode(PhoneNumber phone) =>
      guard(() async => (await _remote.requestCode(phone.value)).toDomain());

  @override
  Future<Result<OtpVerification>> verifyCode(PhoneNumber phone, OtpCode code) => guard(() async {
    final response = await _remote.verifyCode(phone: phone.value, code: code.value);
    if (response.status == OtpVerifyResponseDto.profileRequired && response.registrationToken != null) {
      return OtpProfileRequired(phone: phone, registrationToken: response.registrationToken!);
    }
    final user = response.user;
    final access = response.accessToken;
    final refresh = response.refreshToken;
    if (user == null || access == null || refresh == null) {
      throw const FormatException('Respuesta de verificación incompleta');
    }
    await _tokenStorage.save((accessToken: access, refreshToken: refresh));
    return OtpSignedIn(user.toDomain());
  });

  @override
  Future<Result<AuthUser>> completeProfile({
    required String registrationToken,
    required PersonName firstName,
    required PersonName lastName,
  }) => guard(() async {
    final response = await _remote.register(
      registrationToken: registrationToken,
      firstName: firstName.value,
      lastName: lastName.value,
    );
    await _tokenStorage.save((accessToken: response.accessToken, refreshToken: response.refreshToken));
    return response.user.toDomain();
  });

  @override
  Future<Result<AuthUser>> updateProfile({
    required PersonName firstName,
    required PersonName lastName,
    EmailAddress? email,
  }) => guard(() async {
    final user = await _remote.updateMe(firstName: firstName.value, lastName: lastName.value, email: email?.value);
    return user.toDomain();
  });

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    if (await _tokenStorage.read() == null) return const Result.ok(null);

    final result = await guard(() async => (await _remote.me()).toDomain());
    return switch (result) {
      Ok(:final value) => Result.ok(value),
      // Token inválido y refresh fallido: sesión terminada, no es un error.
      Err(failure: UnauthorizedFailure()) => await _clearAndReturnNull(),
      Err(:final failure) => Result.err(failure),
    };
  }

  @override
  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    await _tokenStorage.clear();
    if (tokens == null) return;
    // Revocar en el backend es best-effort: localmente la sesión ya terminó.
    await guard(() => _remote.logout(tokens.refreshToken));
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final result = await guard(_remote.deleteAccount);
    if (result is Ok<void>) await _tokenStorage.clear();
    return result;
  }

  Future<Result<AuthUser?>> _clearAndReturnNull() async {
    await _tokenStorage.clear();
    return const Result.ok(null);
  }
}
