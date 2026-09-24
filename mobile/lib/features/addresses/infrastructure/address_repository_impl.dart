import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/features/addresses/domain/address.dart';

/// Direcciones guardadas en el dispositivo. Cuando exista `/users/me/addresses`
/// este repositorio sincroniza con el backend sin que cambie la UI.
class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl(this._store);

  static const _key = 'chaski.addresses';
  static const _version = 1;

  final LocalJsonStore _store;

  @override
  Future<AddressBook> load() async {
    final json = await _store.read(_key);
    if (json is! Map || json['v'] != _version) return AddressBook.empty;
    try {
      return AddressBook(
        selectedId: json['selectedId'] as String?,
        addresses: [
          for (final a in (json['addresses'] as List).cast<Map<dynamic, dynamic>>())
            Address(
              id: a['id'] as String,
              kind: AddressKind.values.byName(a['kind'] as String),
              label: a['label'] as String?,
              street: a['street'] as String,
              reference: a['reference'] as String? ?? '',
              coordinates: GeoCoordinates.trusted((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
            ),
        ],
      );
    } on Object {
      return AddressBook.empty;
    }
  }

  @override
  Future<void> save(AddressBook book) => _store.write(_key, {
    'v': _version,
    'selectedId': book.selectedId,
    'addresses': [
      for (final a in book.addresses)
        {
          'id': a.id,
          'kind': a.kind.name,
          'label': a.label,
          'street': a.street,
          'reference': a.reference,
          'lat': a.coordinates.latitude,
          'lng': a.coordinates.longitude,
        },
    ],
  });
}
