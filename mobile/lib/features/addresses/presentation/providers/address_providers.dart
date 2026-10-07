import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/infrastructure/address_repository_impl.dart';
import 'package:chaski/features/addresses/infrastructure/synced_address_repository.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_providers.g.dart';

/// Con la API, local primero y sincronizado con la cuenta: al entrar o salir
/// de la sesión el repositorio cambia y la libreta se vuelve a cargar.
@Riverpod(keepAlive: true)
AddressRepository addressRepository(Ref ref) {
  final store = ref.watch(localJsonStoreProvider);
  final local = AddressRepositoryImpl(store);
  if (ref.watch(appEnvProvider).useFakeData) return local;
  return SyncedAddressRepository(
    local: local,
    store: store,
    api: ref.watch(apiClientProvider),
    userId: ref.watch(authSessionProvider).value?.id,
  );
}

/// Libreta de direcciones. La seleccionada es la ubicación de entrega de toda
/// la app (negocios cercanos, tiempos y envío).
@Riverpod(keepAlive: true)
class AddressBookController extends _$AddressBookController {
  @override
  Future<AddressBook> build() async {
    final book = await ref.watch(addressRepositoryProvider).load();
    _syncLocation(book);
    return book;
  }

  AddressBook get _book => state.value ?? AddressBook.empty;

  Future<void> _commit(AddressBook next) async {
    state = AsyncData(next);
    _syncLocation(next);
    await ref.read(addressRepositoryProvider).save(next);
  }

  void _syncLocation(AddressBook book) {
    final selected = book.selected;
    if (selected == null) return;
    ref
        .read(currentDeliveryLocationProvider.notifier)
        .change(DeliveryLocation(label: selected.street, coordinates: selected.coordinates));
  }

  Future<void> save(Address address) => _commit(_book.save(address));

  /// Grados por px del plano esquemático (~1 m por px en Espinar).
  static const degreesPerPx = 0.00001;

  /// Guarda una dirección nueva marcada en el plano. Sin geocodificación: parte
  /// del punto de entrega actual y se corre lo que se movió el plano
  /// ([movedX]/[movedY] en px; arrastrar a la derecha = ir al oeste).
  Future<Address> addFromPlan({
    required AddressKind kind,
    required StreetLine street,
    String reference = '',
    String? label,
    double movedX = 0,
    double movedY = 0,
  }) async {
    final center = ref.read(currentDeliveryLocationProvider).coordinates;
    final address = Address(
      id: 'adr_${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      label: kind == AddressKind.other ? label?.trim() : null,
      street: street.value,
      reference: reference.trim(),
      coordinates: GeoCoordinates.trusted(center.latitude + movedY * degreesPerPx, center.longitude - movedX * degreesPerPx),
    );
    await save(address);
    return address;
  }

  Future<void> select(String id) => _commit(_book.select(id));

  Future<void> remove(String id) => _commit(_book.remove(id));
}

/// Dirección que recibe los pedidos (o `null` si aún no hay ninguna).
@riverpod
Address? selectedAddress(Ref ref) => ref.watch(addressBookControllerProvider).value?.selected;
