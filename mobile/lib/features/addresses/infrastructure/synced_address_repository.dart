import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/features/addresses/domain/address.dart';

/// Direcciones local primero, sincronizadas con `/users/me/addresses`.
///
/// - Se guarda siempre en el dispositivo y después se sube la libreta
///   entera; sin red, la app sigue funcionando con lo local.
/// - Al cargar: si el servidor tiene direcciones, mandan esas; si está vacío,
///   se suben las locales (p. ej. la primera vez tras actualizar la app).
/// - La caché recuerda de quién es: en un teléfono compartido, las
///   direcciones de una persona nunca se suben a la cuenta de otra.
class SyncedAddressRepository implements AddressRepository {
  SyncedAddressRepository({
    required AddressRepository local,
    required LocalJsonStore store,
    required ApiClient api,
    required String? userId,
  }) : _local = local,
       _store = store,
       _api = api,
       _userId = userId;

  static const _ownerKey = 'chaski.addresses.owner';
  static const _path = '/users/me/addresses';

  final AddressRepository _local;
  final LocalJsonStore _store;
  final ApiClient _api;

  /// `null` = sin sesión: solo en el dispositivo.
  final String? _userId;

  @override
  Future<AddressBook> load() async {
    final local = await _local.load();
    final userId = _userId;
    if (userId == null) return local;

    final owner = await _store.read(_ownerKey) as String?;
    final localIsMine = owner == null || owner == userId;
    try {
      final remote = AddressBookJson.decode(await _api.get(_path));
      if (remote.addresses.isNotEmpty || !localIsMine) {
        await _keep(remote, userId);
        return remote;
      }
      if (local.addresses.isNotEmpty) await _upload(local);
      await _store.write(_ownerKey, userId);
      return local;
    } on Object {
      // Sin red o error del servidor: lo local, si es de esta persona.
      return localIsMine ? local : AddressBook.empty;
    }
  }

  @override
  Future<void> save(AddressBook book) async {
    await _local.save(book);
    final userId = _userId;
    if (userId == null) return;
    await _store.write(_ownerKey, userId);
    try {
      await _upload(book);
    } on Object {
      // Queda guardado en el dispositivo; se sube con el próximo cambio.
    }
  }

  Future<void> _upload(AddressBook book) =>
      _api.put(_path, body: AddressBookJson.encode(book));

  Future<void> _keep(AddressBook book, String userId) async {
    await _local.save(book);
    await _store.write(_ownerKey, userId);
  }
}

/// Contrato JSON de la libreta en la API.
abstract final class AddressBookJson {
  static const Map<AddressKind, String> _kinds = {
    AddressKind.home: 'HOME',
    AddressKind.work: 'WORK',
    AddressKind.other: 'OTHER',
  };

  static Map<String, Object?> encode(AddressBook book) => {
    'selectedId': book.selectedId,
    'addresses': [
      for (final a in book.addresses)
        {
          'id': a.id,
          'kind': _kinds[a.kind],
          'label': a.label,
          'street': a.street,
          'reference': a.reference,
          'latitude': a.coordinates.latitude,
          'longitude': a.coordinates.longitude,
        },
    ],
  };

  static AddressBook decode(Object? json) {
    final map = json! as Map<String, dynamic>;
    final byName = {for (final e in _kinds.entries) e.value: e.key};
    return AddressBook(
      selectedId: map['selectedId'] as String?,
      addresses: [
        for (final a in (map['addresses'] as List).cast<Map<String, dynamic>>())
          Address(
            id: a['id'] as String,
            kind: byName[a['kind']] ?? AddressKind.other,
            label: a['label'] as String?,
            street: a['street'] as String,
            reference: a['reference'] as String? ?? '',
            coordinates: GeoCoordinates.trusted(
              (a['latitude'] as num).toDouble(),
              (a['longitude'] as num).toDouble(),
            ),
          ),
      ],
    );
  }
}
