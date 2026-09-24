import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/auth/domain/entities/auth_user.dart';
import 'package:chaski/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser?>> call() => _repository.restoreSession();
}
