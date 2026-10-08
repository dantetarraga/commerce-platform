import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/auth/domain/entities/auth_user.dart';
import 'package:apamuy/features/auth/domain/repositories/auth_repository.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({required PersonName firstName, required PersonName lastName, EmailAddress? email}) =>
      _repository.updateProfile(firstName: firstName, lastName: lastName, email: email);
}
