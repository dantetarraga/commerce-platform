import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/storage/token_storage.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'package:apamuy/features/auth/infrastructure/models/auth_dtos.dart';

/// Simula `/auth/otp/*`, `/auth/register` y `/users/me` en memoria: todo celular
/// recibe [demoCode]; [demoPhone] y los socios del seed ya tienen cuenta.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._backend, this._tokenStorage);

  static const demoPhone = '984123456';
  static const demoCode = '123456';
  static const demoMerchantPhone = '910000000';
  static const demoCourierPhone = '900000101';
  static const _tokenPrefix = 'fake-access.';
  static const _registrationPrefix = 'fake-registration.';

  final FakeBackend _backend;
  final TokenStorage _tokenStorage;

  final Map<String, Map<String, dynamic>> _usersByPhone = {
    demoPhone: {
      'id': 'usr_demo_customer',
      'phone': demoPhone,
      'firstName': 'Alex',
      'lastName': 'Quispe',
      'email': null,
      'avatarUrl': null,
      'roles': ['CUSTOMER'],
    },
    demoMerchantPhone: {
      'id': 'usr_owner_chaski_dorado',
      'phone': demoMerchantPhone,
      'firstName': 'Don Julián',
      'lastName': '',
      'email': null,
      'avatarUrl': null,
      'roles': ['MERCHANT'],
    },
    demoCourierPhone: {
      'id': 'usr_courier_luis',
      'phone': demoCourierPhone,
      'firstName': 'Luis',
      'lastName': 'Quispe',
      'email': null,
      'avatarUrl': null,
      'roles': ['COURIER'],
    },
  };
  final Set<String> _codesSent = {};

  @override
  Future<OtpChallengeDto> requestCode(String phone) async {
    await _backend.delay();
    _codesSent.add(phone);
    return OtpChallengeDto.fromJson({'phone': phone, 'resendAfterSeconds': 30, 'codeLength': 6});
  }

  @override
  Future<OtpVerifyResponseDto> verifyCode({required String phone, required String code}) async {
    await _backend.delay();
    if (!_codesSent.contains(phone)) {
      throw const ApiException(statusCode: 409, code: 'OTP_NOT_REQUESTED', message: 'Pide un código primero.');
    }
    if (code != demoCode) {
      throw const ApiException(
        statusCode: 422,
        code: 'OTP_INVALID',
        message: 'Ese código no coincide. Revisa el mensaje e inténtalo otra vez.',
      );
    }
    final user = _usersByPhone[phone];
    if (user == null) {
      return OtpVerifyResponseDto.fromJson({'status': 'PROFILE_REQUIRED', 'registrationToken': '$_registrationPrefix$phone'});
    }
    return OtpVerifyResponseDto.fromJson({'status': 'AUTHENTICATED', ..._tokens(user)});
  }

  @override
  Future<AuthResponseDto> register({
    required String registrationToken,
    required String firstName,
    required String lastName,
  }) async {
    await _backend.delay();
    if (!registrationToken.startsWith(_registrationPrefix)) {
      throw const ApiException(statusCode: 401, code: 'REGISTRATION_EXPIRED', message: 'Vuelve a verificar tu número.');
    }
    final phone = registrationToken.substring(_registrationPrefix.length);
    final user = <String, dynamic>{
      'id': 'usr_${DateTime.now().microsecondsSinceEpoch}',
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': null,
      'avatarUrl': null,
      'roles': ['CUSTOMER'],
    };
    _usersByPhone[phone] = user;
    return AuthResponseDto.fromJson(_tokens(user));
  }

  @override
  Future<UserDto> me() async {
    await _backend.delay();
    return UserDto.fromJson(await _currentUser());
  }

  @override
  Future<UserDto> updateMe({required String firstName, required String lastName, String? email}) async {
    await _backend.delay();
    final user = await _currentUser();
    if (email != null && _usersByPhone.values.any((u) => u['email'] == email && u['id'] != user['id'])) {
      throw const ApiException(
        statusCode: 409,
        code: 'EMAIL_ALREADY_EXISTS',
        message: 'Ese correo ya está en uso por otra cuenta.',
      );
    }
    user
      ..['firstName'] = firstName
      ..['lastName'] = lastName
      ..['email'] = email;
    return UserDto.fromJson(user);
  }

  /// Simula el header Authorization que agregaría AuthInterceptor.
  Future<Map<String, dynamic>> _currentUser() async {
    final tokens = await _tokenStorage.read();
    final userId = tokens?.accessToken.replaceFirst(_tokenPrefix, '');
    final user = _usersByPhone.values.where((u) => u['id'] == userId).firstOrNull;
    if (user == null) {
      throw const ApiException(statusCode: 401, code: 'TOKEN_EXPIRED', message: 'Sesión expirada.');
    }
    return user;
  }

  @override
  Future<void> logout(String refreshToken) => _backend.delay();

  @override
  Future<void> deleteAccount() => _backend.delay();

  Map<String, Object?> _tokens(Map<String, dynamic> user) => {
    'user': user,
    'accessToken': '$_tokenPrefix${user['id']}',
    'refreshToken': 'fake-refresh.${user['id']}',
  };
}
