// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Con la API, local primero y sincronizado con la cuenta: al entrar o salir
/// de la sesión el repositorio cambia y la libreta se vuelve a cargar.

@ProviderFor(addressRepository)
final addressRepositoryProvider = AddressRepositoryProvider._();

/// Con la API, local primero y sincronizado con la cuenta: al entrar o salir
/// de la sesión el repositorio cambia y la libreta se vuelve a cargar.

final class AddressRepositoryProvider
    extends
        $FunctionalProvider<
          AddressRepository,
          AddressRepository,
          AddressRepository
        >
    with $Provider<AddressRepository> {
  /// Con la API, local primero y sincronizado con la cuenta: al entrar o salir
  /// de la sesión el repositorio cambia y la libreta se vuelve a cargar.
  AddressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressRepositoryHash();

  @$internal
  @override
  $ProviderElement<AddressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddressRepository create(Ref ref) {
    return addressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressRepository>(value),
    );
  }
}

String _$addressRepositoryHash() => r'062c5e88901e84d78ae79dcf2681a5b43031799a';

/// Libreta de direcciones. La seleccionada define dónde se entregan los
/// pedidos: al cambiar, actualiza la ubicación de entrega de toda la app
/// (negocios cercanos, tiempos y envío se recalculan).

@ProviderFor(AddressBookController)
final addressBookControllerProvider = AddressBookControllerProvider._();

/// Libreta de direcciones. La seleccionada define dónde se entregan los
/// pedidos: al cambiar, actualiza la ubicación de entrega de toda la app
/// (negocios cercanos, tiempos y envío se recalculan).
final class AddressBookControllerProvider
    extends $AsyncNotifierProvider<AddressBookController, AddressBook> {
  /// Libreta de direcciones. La seleccionada define dónde se entregan los
  /// pedidos: al cambiar, actualiza la ubicación de entrega de toda la app
  /// (negocios cercanos, tiempos y envío se recalculan).
  AddressBookControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressBookControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressBookControllerHash();

  @$internal
  @override
  AddressBookController create() => AddressBookController();
}

String _$addressBookControllerHash() =>
    r'037673e6d51c1b86928741bf605e254e858aeaeb';

/// Libreta de direcciones. La seleccionada define dónde se entregan los
/// pedidos: al cambiar, actualiza la ubicación de entrega de toda la app
/// (negocios cercanos, tiempos y envío se recalculan).

abstract class _$AddressBookController extends $AsyncNotifier<AddressBook> {
  FutureOr<AddressBook> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AddressBook>, AddressBook>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AddressBook>, AddressBook>,
              AsyncValue<AddressBook>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Dirección que recibe los pedidos (o `null` si aún no hay ninguna).

@ProviderFor(selectedAddress)
final selectedAddressProvider = SelectedAddressProvider._();

/// Dirección que recibe los pedidos (o `null` si aún no hay ninguna).

final class SelectedAddressProvider
    extends $FunctionalProvider<Address?, Address?, Address?>
    with $Provider<Address?> {
  /// Dirección que recibe los pedidos (o `null` si aún no hay ninguna).
  SelectedAddressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAddressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAddressHash();

  @$internal
  @override
  $ProviderElement<Address?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Address? create(Ref ref) {
    return selectedAddress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Address? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Address?>(value),
    );
  }
}

String _$selectedAddressHash() => r'5910f82e5318a9c6022fc7bb2f8a02c63a60242c';
