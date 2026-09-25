import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/infrastructure/address_repository_impl.dart';
import 'package:chaski/features/addresses/infrastructure/synced_address_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

final _casa = Address(
  id: 'adr_1',
  kind: AddressKind.home,
  street: 'Jr. Túpac Amaru 214',
  reference: 'Puerta verde',
  coordinates: GeoCoordinates.trusted(-14.7936, -71.4128),
);
final _mine = AddressBook(addresses: [_casa], selectedId: 'adr_1');
final _serverBook = AddressBook(
  addresses: [
    Address(
      id: 'adr_9',
      kind: AddressKind.work,
      street: 'Av. Espinar 100',
      coordinates: GeoCoordinates.trusted(-14.79, -71.41),
    ),
  ],
  selectedId: 'adr_9',
);

void main() {
  late MemoryJsonStore store;
  late AddressRepositoryImpl local;
  late _MockApiClient api;

  SyncedAddressRepository repo(String? userId) => SyncedAddressRepository(
    local: local,
    store: store,
    api: api,
    userId: userId,
  );

  void serverReturns(AddressBook book) => when(
    () => api.get('/users/me/addresses'),
  ).thenAnswer((_) async => AddressBookJson.encode(book));

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() {
    store = MemoryJsonStore();
    local = AddressRepositoryImpl(store);
    api = _MockApiClient();
    when(
      () => api.put(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  test('sin sesión solo usa el dispositivo', () async {
    await repo(null).save(_mine);
    expect(await repo(null).load(), _mine);
    verifyNever(() => api.get(any()));
    verifyNever(() => api.put(any(), body: any(named: 'body')));
  });

  test(
    'si el servidor tiene direcciones, mandan esas y quedan en caché',
    () async {
      await local.save(_mine);
      serverReturns(_serverBook);

      expect(await repo('usr_a').load(), _serverBook);
      expect(await local.load(), _serverBook);
    },
  );

  test('servidor vacío: sube las locales de esta persona', () async {
    await local.save(_mine);
    serverReturns(AddressBook.empty);

    expect(await repo('usr_a').load(), _mine);
    final body =
        verify(
              () => api.put(
                '/users/me/addresses',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Map<String, Object?>;
    expect(body['selectedId'], 'adr_1');
  });

  test('las direcciones de otra persona no se suben ni se muestran', () async {
    await repo('usr_a').save(_mine);
    clearInteractions(api);
    serverReturns(AddressBook.empty);

    expect(await repo('usr_b').load(), AddressBook.empty);
    verifyNever(() => api.put(any(), body: any(named: 'body')));
    expect(await local.load(), AddressBook.empty);
  });

  test('sin red: lo local si es de esta persona', () async {
    await repo('usr_a').save(_mine);
    when(
      () => api.get('/users/me/addresses'),
    ).thenThrow(const NetworkException());

    expect(await repo('usr_a').load(), _mine);
    expect(await repo('usr_b').load(), AddressBook.empty);
  });

  test('guardar sin red deja la libreta en el dispositivo', () async {
    when(
      () => api.put(any(), body: any(named: 'body')),
    ).thenThrow(const NetworkException());

    await repo('usr_a').save(_mine);
    expect(await local.load(), _mine);
  });

  test('el JSON ida y vuelta conserva la libreta', () {
    expect(AddressBookJson.decode(AddressBookJson.encode(_mine)), _mine);
  });
}
