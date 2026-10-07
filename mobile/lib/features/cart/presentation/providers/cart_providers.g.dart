// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cartRepository)
final cartRepositoryProvider = CartRepositoryProvider._();

final class CartRepositoryProvider
    extends $FunctionalProvider<CartRepository, CartRepository, CartRepository>
    with $Provider<CartRepository> {
  CartRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartRepositoryHash();

  @$internal
  @override
  $ProviderElement<CartRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CartRepository create(Ref ref) {
    return cartRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartRepository>(value),
    );
  }
}

String _$cartRepositoryHash() => r'42f6d6a70aeac6f99b0336f9c0aee94bf26d6124';

/// La bolsa del usuario; cada cambio se guarda en el dispositivo. La lógica
/// vive en [Cart]; aquí solo se orquesta y persiste.

@ProviderFor(CartController)
final cartControllerProvider = CartControllerProvider._();

/// La bolsa del usuario; cada cambio se guarda en el dispositivo. La lógica
/// vive en [Cart]; aquí solo se orquesta y persiste.
final class CartControllerProvider
    extends $AsyncNotifierProvider<CartController, Cart> {
  /// La bolsa del usuario; cada cambio se guarda en el dispositivo. La lógica
  /// vive en [Cart]; aquí solo se orquesta y persiste.
  CartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartControllerHash();

  @$internal
  @override
  CartController create() => CartController();
}

String _$cartControllerHash() => r'20a5c49370a0643e7d2918fb9f7f3eac674a7b29';

/// La bolsa del usuario; cada cambio se guarda en el dispositivo. La lógica
/// vive en [Cart]; aquí solo se orquesta y persiste.

abstract class _$CartController extends $AsyncNotifier<Cart> {
  FutureOr<Cart> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Cart>, Cart>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Cart>, Cart>,
              AsyncValue<Cart>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Cantidad de productos en la bolsa (para la barra de compra y badges).

@ProviderFor(cartItemCount)
final cartItemCountProvider = CartItemCountProvider._();

/// Cantidad de productos en la bolsa (para la barra de compra y badges).

final class CartItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Cantidad de productos en la bolsa (para la barra de compra y badges).
  CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cartItemCountHash() => r'e1a38a82b251dbb9977230b9739c95306feb2620';
