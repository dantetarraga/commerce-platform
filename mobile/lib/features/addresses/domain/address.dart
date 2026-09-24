import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

enum AddressKind { home, work, other }

/// Calle y número ("Jr. Túpac Amaru 214"). Entre 4 y 120 caracteres.
final class StreetLine extends Equatable {
  const StreetLine._(this.value);

  static const minLength = 4;
  static const maxLength = 120;

  final String value;

  static Validated<StreetLine> create(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return const Invalid(EmptyValue());
    if (trimmed.length < minLength) return const Invalid(TooShort(minLength));
    if (trimmed.length > maxLength) return const Invalid(TooLong(maxLength));
    return Valid(StreetLine._(trimmed));
  }

  @override
  List<Object?> get props => [value];
}

/// Dirección de entrega guardada.
final class Address extends Equatable {
  const Address({
    required this.id,
    required this.kind,
    required this.street,
    required this.coordinates,
    this.label,
    this.reference = '',
  });

  final String id;
  final AddressKind kind;

  /// Nombre propio cuando `kind == other` ("Casa de mi mamá").
  final String? label;
  final String street;

  /// Cómo llegar: "puerta verde, al costado de la botica". Clave en Espinar.
  final String reference;
  final GeoCoordinates coordinates;

  String get title => switch (kind) {
    AddressKind.home => 'Casa',
    AddressKind.work => 'Trabajo',
    AddressKind.other => (label?.trim().isNotEmpty ?? false) ? label!.trim() : 'Otra dirección',
  };

  @override
  List<Object?> get props => [id, kind, label, street, reference, coordinates];
}

/// Libreta de direcciones: las guardadas y cuál recibe los pedidos.
final class AddressBook extends Equatable {
  const AddressBook({this.addresses = const [], this.selectedId});

  static const empty = AddressBook();
  static const maxAddresses = 10;

  final List<Address> addresses;
  final String? selectedId;

  Address? get selected => addresses.where((a) => a.id == selectedId).firstOrNull ?? addresses.firstOrNull;

  bool get isFull => addresses.length >= maxAddresses;

  /// Agrega o reemplaza (mismo id) y la deja seleccionada.
  AddressBook save(Address address) {
    final index = addresses.indexWhere((a) => a.id == address.id);
    final next = [...addresses];
    if (index >= 0) {
      next[index] = address;
    } else {
      if (isFull) return this;
      next.add(address);
    }
    return AddressBook(addresses: next, selectedId: address.id);
  }

  AddressBook remove(String id) {
    final next = addresses.where((a) => a.id != id).toList();
    return AddressBook(addresses: next, selectedId: selectedId == id ? next.firstOrNull?.id : selectedId);
  }

  AddressBook select(String id) =>
      addresses.any((a) => a.id == id) ? AddressBook(addresses: addresses, selectedId: id) : this;

  @override
  List<Object?> get props => [addresses, selectedId];
}

abstract interface class AddressRepository {
  Future<AddressBook> load();

  Future<void> save(AddressBook book);
}
