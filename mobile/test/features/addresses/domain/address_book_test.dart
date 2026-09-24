import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/infrastructure/address_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Address address(String id, {AddressKind kind = AddressKind.home, String? label}) => Address(
    id: id,
    kind: kind,
    label: label,
    street: 'Jr. Grau $id',
    reference: 'Puerta verde',
    coordinates: GeoCoordinates.trusted(-14.79, -71.41),
  );

  test('guardar deja la nueva dirección seleccionada', () {
    final book = AddressBook.empty.save(address('1')).save(address('2'));
    expect(book.selected?.id, '2');
    expect(book.select('1').selected?.id, '1');
  });

  test('borrar la seleccionada pasa a la siguiente disponible', () {
    final book = AddressBook.empty.save(address('1')).save(address('2')).remove('2');
    expect(book.selected?.id, '1');
    expect(AddressBook.empty.save(address('1')).remove('1').selected, isNull);
  });

  test('guardar con el mismo id reemplaza en vez de duplicar', () {
    final book = AddressBook.empty.save(address('1')).save(address('1', kind: AddressKind.work));
    expect(book.addresses, hasLength(1));
    expect(book.selected?.title, 'Trabajo');
  });

  test('el título usa el nombre propio en "otra"', () {
    expect(address('1', kind: AddressKind.other, label: 'Casa de mi mamá').title, 'Casa de mi mamá');
    expect(address('1', kind: AddressKind.other).title, 'Otra dirección');
  });

  test('StreetLine exige un mínimo legible', () {
    expect(StreetLine.create('').failureOrNull, const EmptyValue());
    expect(StreetLine.create('Jr').failureOrNull, const TooShort(StreetLine.minLength));
    expect(StreetLine.create('  Jr.   Grau 205 ').valueOrNull?.value, 'Jr. Grau 205');
  });

  test('el repositorio guarda y recupera la libreta', () async {
    final repo = AddressRepositoryImpl(MemoryJsonStore());
    final book = AddressBook.empty.save(address('1')).save(address('2', kind: AddressKind.other, label: 'Chamba'));
    await repo.save(book);
    expect(await repo.load(), book);
  });
}
