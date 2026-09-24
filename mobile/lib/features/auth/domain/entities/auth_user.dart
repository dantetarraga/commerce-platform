import 'package:chaski/core/domain/email_address.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:equatable/equatable.dart';

enum UserRole { customer, merchant, courier, admin }

/// Usuario autenticado. La identidad es el celular (se entra con código por
/// SMS/WhatsApp); el correo es opcional.
final class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final PhoneNumber phone;
  final String firstName;
  final String lastName;
  final EmailAddress? email;
  final String? avatarUrl;
  final Set<UserRole> roles;

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'.toUpperCase();

  bool get isCustomer => roles.contains(UserRole.customer);

  @override
  List<Object?> get props => [id, phone, firstName, lastName, email, avatarUrl, roles];
}
