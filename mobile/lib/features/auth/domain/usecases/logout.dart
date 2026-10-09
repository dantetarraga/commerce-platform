import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  const Logout(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

/// Eliminar la cuenta: el backend se niega si hay un pedido en curso o es un socio.
class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccount();
}
