import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
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
  AuthRepositoryImpl(this._remote, this._tokenStorage, [LocalJsonStore? userCache])
    : _userCache = userCache ?? MemoryJsonStore();

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  /// La última cuenta vista (sin tokens): sin señal al abrir, la app entra con ella
  /// en vez de mandar al login.
  final LocalJsonStore _userCache;

  static const _userKey = 'apamuy.lastUser';

  Future<AuthUser> _remember(UserDto user) async {
    await _userCache.write(_userKey, {
      'id': user.id,
      'phone': user.phone,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'avatarUrl': user.avatarUrl,
      'roles': user.roles,
    });
    return user.toDomain();
  }

  Future<AuthUser?> _lastUser() async {
    try {
      final json = await _userCache.read(_userKey);
      return json is Map<String, dynamic> ? UserDto.fromJson(json).toDomain() : null;
    } on Object {
      return null;
    }
  }

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
    return OtpSignedIn(await _remember(user));
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
    return _remember(response.user);
  });

  @override
  Future<Result<AuthUser>> updateProfile({
    required PersonName firstName,
    required PersonName lastName,
    EmailAddress? email,
  }) => guard(() async {
    final user = await _remote.updateMe(firstName: firstName.value, lastName: lastName.value, email: email?.value);
    return _remember(user);
  });

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    final StoredTokens? tokens;
    try {
      tokens = await _tokenStorage.read();
    } on Object {
      // P. ej. tras restaurar un respaldo del teléfono: la llave ya no descifra.
      return _clearAndReturnNull();
    }
    if (tokens == null) return const Result.ok(null);

    final result = await guard(() async => _remember(await _remote.me()));
    return switch (result) {
      Ok(:final value) => Result.ok(value),
      // Token inválido y refresh fallido: sesión terminada, no es un error.
      Err(failure: UnauthorizedFailure()) => await _clearAndReturnNull(),
      // Sin señal: se entra con la última cuenta y cada pantalla ofrece reintentar.
      Err(:final failure) => switch (await _lastUser()) {
        final user? => Result.ok(user),
        null => Result.err(failure),
      },
    };
  }

  @override
  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    await _tokenStorage.clear();
    await _userCache.remove(_userKey);
    if (tokens == null) return;
    // Revocar en el backend es best-effort: localmente la sesión ya terminó.
    await guard(() => _remote.logout(tokens.refreshToken));
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final result = await guard(_remote.deleteAccount);
    if (result is Ok<void>) {
      await _tokenStorage.clear();
      await _userCache.remove(_userKey);
    }
    return result;
  }

  Future<Result<AuthUser?>> _clearAndReturnNull() async {
    await _userCache.remove(_userKey);
    try {
      await _tokenStorage.clear();
    } on Object {
      // Si tampoco se puede borrar, igual se pide entrar de nuevo.
    }
    return const Result.ok(null);
  }
}
