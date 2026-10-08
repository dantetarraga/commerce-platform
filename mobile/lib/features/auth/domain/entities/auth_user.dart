import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:equatable/equatable.dart';

enum UserRole { customer, merchant, courier, admin }

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
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'
          .toUpperCase();

  bool get isCustomer => roles.contains(UserRole.customer);

  bool get isMerchant => roles.contains(UserRole.merchant);

  bool get isCourier => roles.contains(UserRole.courier);

  bool get isPartner => isMerchant || isCourier;

  @override
  List<Object?> get props => [
    id,
    phone,
    firstName,
    lastName,
    email,
    avatarUrl,
    roles,
  ];
}
