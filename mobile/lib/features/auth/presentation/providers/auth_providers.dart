import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';
import 'package:apamuy/features/auth/domain/usecases/logout.dart';
import 'package:apamuy/features/auth/domain/usecases/phone_auth.dart';
import 'package:apamuy/features/auth/domain/usecases/restore_session.dart';
import 'package:apamuy/features/auth/domain/usecases/update_profile.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'package:apamuy/features/auth/infrastructure/datasources/remote/fake_auth_remote_data_source.dart';
import 'package:apamuy/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeAuthRemoteDataSource(ref.watch(fakeBackendProvider), ref.watch(tokenStorageProvider))
    : ApiAuthRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider), ref.watch(tokenStorageProvider));

@riverpod
RequestCode requestCode(Ref ref) => RequestCode(ref.watch(authRepositoryProvider));

@riverpod
VerifyCode verifyCode(Ref ref) => VerifyCode(ref.watch(authRepositoryProvider));

@riverpod
CompleteProfile completeProfile(Ref ref) => CompleteProfile(ref.watch(authRepositoryProvider));

@riverpod
UpdateProfile updateProfile(Ref ref) => UpdateProfile(ref.watch(authRepositoryProvider));

@riverpod
RestoreSession restoreSession(Ref ref) => RestoreSession(ref.watch(authRepositoryProvider));

@riverpod
Logout logout(Ref ref) => Logout(ref.watch(authRepositoryProvider));
