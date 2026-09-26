import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/cart/domain/repositories/cart_repository.dart';
import 'package:chaski/features/cart/infrastructure/datasources/coupon_remote_data_source.dart';
import 'package:chaski/features/cart/infrastructure/repositories/cart_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_providers.g.dart';

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) => CartRepositoryImpl(
  ref.watch(localJsonStoreProvider),
  ref.watch(appEnvProvider).useFakeData
      ? FakeCouponRemoteDataSource(ref.watch(fakeBackendProvider))
      : ApiCouponRemoteDataSource(ref.watch(apiClientProvider)),
);

/// La bolsa del usuario. Fuente única de verdad: cada cambio se guarda en el
/// dispositivo. La lógica (un negocio por bolsa, fusionar líneas, mínimos)
/// vive en [Cart]; aquí solo se orquesta y persiste.
@Riverpod(keepAlive: true)
class CartController extends _$CartController {
  @override
  Future<Cart> build() => ref.watch(cartRepositoryProvider).load();

  Cart get _cart => state.value ?? Cart.empty;

  Future<void> _commit(Cart next) async {
    state = AsyncData(next);
    await ref.read(cartRepositoryProvider).save(next);
  }

  /// Agrega una línea. Si la bolsa es de otro negocio devuelve el conflicto
  /// sin tocar nada: la UI pregunta y, si confirma, llama a [replaceWith].
  Future<AddToCartResult> add(CartLine line, CartStore store) async {
    await future; // asegura la bolsa cargada
    final result = _cart.add(line, store);
    if (result case Added(:final cart)) await _commit(cart);
    return result;
  }

  Future<void> replaceWith(CartLine line, CartStore store) => _commit(_cart.replaceWith(line, store));

  Future<void> setQuantity(String lineId, Quantity quantity) => _commit(_cart.setQuantity(lineId, quantity));

  Future<void> setNotes(String lineId, String notes) => _commit(_cart.setNotes(lineId, notes));

  /// Quita una línea y devuelve lo necesario para "Deshacer".
  Future<({CartLine line, int index, CartStore store})?> remove(String lineId) async {
    final cart = _cart;
    final index = cart.lines.indexWhere((l) => l.id == lineId);
    final store = cart.store;
    if (index < 0 || store == null) return null;
    final line = cart.lines[index];
    await _commit(cart.remove(lineId));
    return (line: line, index: index, store: store);
  }

  Future<void> restore(({CartLine line, int index, CartStore store}) removed) =>
      _commit(_cart.restore(removed.line, removed.index, removed.store));

  /// Valida el cupón en el backend. Devuelve el error para mostrarlo en línea.
  Future<Failure?> applyCoupon(String code) async {
    final cart = _cart;
    final store = cart.store;
    if (store == null || code.trim().isEmpty) return null;
    final result = await ref
        .read(cartRepositoryProvider)
        .validateCoupon(code: code, storeId: store.id, subtotal: cart.subtotal);
    switch (result) {
      case Ok(:final value):
        await _commit(_cart.applyCoupon(value));
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  Future<void> removeCoupon() => _commit(_cart.removeCoupon());

  /// Nota general para el negocio.
  Future<void> setNote(String note) => _commit(_cart.setNote(note));

  Future<void> clear() => _commit(Cart.empty);
}

/// Cantidad de productos en la bolsa (para la barra de compra y badges).
@riverpod
int cartItemCount(Ref ref) => ref.watch(cartControllerProvider).value?.itemCount ?? 0;
