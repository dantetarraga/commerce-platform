import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/storage/token_storage.dart';
import 'package:apamuy/features/auth/domain/entities/otp.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'package:apamuy/features/auth/infrastructure/models/auth_dtos.dart';
import 'package:apamuy/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/result_helpers.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockRemote remote;
  late _MockTokenStorage storage;
  late AuthRepositoryImpl repository;
  final phone = PhoneNumber.trusted('984123456');
  final code = OtpCode.create('123456').valueOrNull!;

  const userDto = UserDto(
    id: 'u1',
    phone: '984123456',
    firstName: 'Alex',
    lastName: 'Quispe',
    roles: ['CUSTOMER', 'ROL_NUEVO'],
  );

  setUpAll(() => registerFallbackValue((accessToken: '', refreshToken: '')));

  setUp(() {
    remote = _MockRemote();
    storage = _MockTokenStorage();
    repository = AuthRepositoryImpl(remote, storage);
    when(() => storage.save(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
  });

  test('requestCode devuelve el reto con el tiempo de reenvío', () async {
    when(() => remote.requestCode('984123456')).thenAnswer(
      (_) async => const OtpChallengeDto(phone: '984123456', resendAfterSeconds: 30, codeLength: 6),
    );

    final challenge = (await repository.requestCode(phone)).getOrThrow();

    expect(challenge.phone, phone);
    expect(challenge.resendAfter, const Duration(seconds: 30));
  });

  test('un número con cuenta inicia sesión y guarda los tokens', () async {
    when(() => remote.verifyCode(phone: '984123456', code: '123456')).thenAnswer(
      (_) async => const OtpVerifyResponseDto(status: 'AUTHENTICATED', user: userDto, accessToken: 'a', refreshToken: 'r'),
    );

    final verification = (await repository.verifyCode(phone, code)).getOrThrow();

    expect(verification, isA<OtpSignedIn>());
    final user = (verification as OtpSignedIn).user;
    expect(user.fullName, 'Alex Quispe');
    expect(user.isCustomer, isTrue); // el rol desconocido se ignora
    verify(() => storage.save((accessToken: 'a', refreshToken: 'r'))).called(1);
  });

  test('un número nuevo pide completar el perfil sin guardar tokens', () async {
    when(() => remote.verifyCode(phone: any(named: 'phone'), code: any(named: 'code'))).thenAnswer(
      (_) async => const OtpVerifyResponseDto(status: 'PROFILE_REQUIRED', registrationToken: 'reg'),
    );

    final verification = (await repository.verifyCode(phone, code)).getOrThrow();

    expect(verification, OtpProfileRequired(phone: phone, registrationToken: 'reg'));
    verifyNever(() => storage.save(any()));
  });

  test('un código incorrecto llega como BusinessFailure con su código', () async {
    when(() => remote.verifyCode(phone: any(named: 'phone'), code: any(named: 'code'))).thenThrow(
      const ApiException(statusCode: 422, code: 'OTP_INVALID', message: 'Ese código no coincide.'),
    );

    final result = await repository.verifyCode(phone, code);

    expect(failureOf(result), const BusinessFailure('OTP_INVALID', 'Ese código no coincide.'));
  });

  test('completeProfile crea la cuenta y guarda la sesión', () async {
    when(() => remote.register(registrationToken: 'reg', firstName: 'Ana', lastName: 'Huamán')).thenAnswer(
      (_) async => const AuthResponseDto(
        user: UserDto(id: 'u2', phone: '987654321', firstName: 'Ana', lastName: 'Huamán', roles: ['CUSTOMER']),
        accessToken: 'a2',
        refreshToken: 'r2',
      ),
    );

    final user = (await repository.completeProfile(
      registrationToken: 'reg',
      firstName: PersonName.create('Ana').valueOrNull!,
      lastName: PersonName.create('Huamán').valueOrNull!,
    )).getOrThrow();

    expect(user.firstName, 'Ana');
    verify(() => storage.save((accessToken: 'a2', refreshToken: 'r2'))).called(1);
  });

  test('restoreSession sin tokens devuelve null sin llamar a la API', () async {
    when(() => storage.read()).thenAnswer((_) async => null);

    final result = await repository.restoreSession();

    expect(result.getOrThrow(), isNull);
    verifyNever(() => remote.me());
  });

  test('restoreSession con token inválido limpia la sesión', () async {
    when(() => storage.read()).thenAnswer((_) async => (accessToken: 'a', refreshToken: 'r'));
    when(() => remote.me()).thenThrow(const ApiException(statusCode: 401, code: 'TOKEN_EXPIRED', message: 'Sesión expirada.'));

    final result = await repository.restoreSession();

    expect(result.getOrThrow(), isNull);
    verify(() => storage.clear()).called(1);
  });

  test('restoreSession sin red conserva los tokens y devuelve el error', () async {
    when(() => storage.read()).thenAnswer((_) async => (accessToken: 'a', refreshToken: 'r'));
    when(() => remote.me()).thenThrow(const NetworkException());

    final result = await repository.restoreSession();

    expect(failureOf(result), isA<NetworkFailure>());
    verifyNever(() => storage.clear());
  });

  test('logout limpia localmente aunque el backend falle', () async {
    when(() => storage.read()).thenAnswer((_) async => (accessToken: 'a', refreshToken: 'r'));
    when(() => remote.logout('r')).thenThrow(const NetworkException());

    await repository.logout();

    verify(() => storage.clear()).called(1);
  });

  test('updateProfile manda los datos normalizados y devuelve el usuario', () async {
    when(() => remote.updateMe(firstName: 'Alexandra', lastName: 'Quispe', email: 'alex@correo.pe')).thenAnswer(
      (_) async => const UserDto(id: 'u1', phone: '984123456', firstName: 'Alexandra', lastName: 'Quispe', roles: ['CUSTOMER']),
    );

    final user = (await repository.updateProfile(
      firstName: PersonName.create(' Alexandra ').valueOrNull!,
      lastName: PersonName.create('Quispe').valueOrNull!,
      email: EmailAddress.create('Alex@Correo.pe').valueOrNull,
    )).getOrThrow();

    expect(user.firstName, 'Alexandra');
  });

  test('updateProfile con un correo ya usado llega como BusinessFailure', () async {
    when(() => remote.updateMe(firstName: any(named: 'firstName'), lastName: any(named: 'lastName'), email: any(named: 'email')))
        .thenThrow(const ApiException(statusCode: 409, code: 'EMAIL_ALREADY_EXISTS', message: 'Ese correo ya está en uso por otra cuenta.'));

    final result = await repository.updateProfile(
      firstName: PersonName.create('Alex').valueOrNull!,
      lastName: PersonName.create('Quispe').valueOrNull!,
      email: EmailAddress.create('otro@correo.pe').valueOrNull,
    );

    expect(failureOf(result), const BusinessFailure('EMAIL_ALREADY_EXISTS', 'Ese correo ya está en uso por otra cuenta.'));
  });
}
