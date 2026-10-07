import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/home/domain/repeat_order.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/presentation/providers/products_providers.dart';
import 'package:chaski/features/stores/presentation/providers/stores_providers.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

/// Negocios abiertos ahora por id de categoría.
@riverpod
Map<String, int> openStoresByCategory(Ref ref) {
  final stores = ref.watch(storesProvider()).value?.items ?? const <StoreSummary>[];
  final count = <String, int>{};
  for (final store in stores.where((s) => s.isOpenNow)) {
    for (final id in store.categoryIds) {
      count[id] = (count[id] ?? 0) + 1;
    }
  }
  return count;
}

/// Pedidos entregados por id de negocio ("Lo pediste 4 veces").
@riverpod
Map<String, int> deliveredCountByStore(Ref ref) {
  final history = ref.watch(ordersHistoryProvider).value ?? const <Order>[];
  final count = <String, int>{};
  for (final order in history.where((o) => o.status == OrderStatus.delivered)) {
    count[order.store.id] = (count[order.store.id] ?? 0) + 1;
  }
  return count;
}

/// Cómo terminó un "Repetir".
sealed class RepeatOutcome {
  const RepeatOutcome();
}

/// No se pudo cargar el negocio.
final class RepeatFailed extends RepeatOutcome {
  const RepeatFailed(this.storeName, this.failure);
  final String storeName;
  final Failure failure;
}

/// El negocio está cerrado o no llega a la dirección.
final class RepeatUnavailable extends RepeatOutcome {
  const RepeatUnavailable(this.store);
  final StoreSummary store;
}

/// Nada de ese pedido sigue disponible.
final class RepeatNothingLeft extends RepeatOutcome {
  const RepeatNothingLeft(this.store);
  final StoreSummary store;
}

/// El usuario prefirió mantener su bolsa, o ya había un "Repetir" en curso.
final class RepeatCancelled extends RepeatOutcome {
  const RepeatCancelled();
}

final class RepeatAdded extends RepeatOutcome {
  const RepeatAdded(this.store, {required this.missing});
  final StoreSummary store;
  final int missing;
}

/// Ejecuta "Repetir" de punta a punta: carga el negocio, rearma las líneas con
/// [RepeatOrder] y las pone en la bolsa. El estado dice si hay uno en curso.
@Riverpod(keepAlive: true)
class RepeatOrderController extends _$RepeatOrderController {
  @override
  bool build() => false;

  /// [confirmReplace] pregunta si se vacía una bolsa de otro negocio.
  Future<RepeatOutcome> run(
    Order order, {
    required Future<bool> Function(CartStore current, CartStore incoming) confirmReplace,
  }) async {
    if (state) return const RepeatCancelled();
    state = true;
    try {
      return await _run(order, confirmReplace);
    } finally {
      state = false;
    }
  }

  Future<RepeatOutcome> _run(Order order, Future<bool> Function(CartStore, CartStore) confirmReplace) async {
    final near = ref.read(currentDeliveryLocationProvider).coordinates;
    final detail = await ref.read(storesRepositoryProvider).getStoreDetail(order.store.id, near: near);
    final StoreSummary store;
    switch (detail) {
      case Ok(:final value):
        store = value.summary;
      case Err(:final failure):
        return RepeatFailed(order.store.name, failure);
    }
    if (!store.canOrder) return RepeatUnavailable(store);

    final repeated = await RepeatOrder(ref.read(productsRepositoryProvider)).call(order, near: near);
    if (repeated.lines.isEmpty) return RepeatNothingLeft(store);

    final cart = ref.read(cartControllerProvider.notifier);
    final cartStore = store.toCartStore();
    final [first, ...rest] = repeated.lines;
    if (await cart.add(first, cartStore) case StoreConflict(:final current, :final incoming)) {
      if (!await confirmReplace(current, incoming)) return const RepeatCancelled();
      await cart.replaceWith(first, cartStore);
    }
    for (final line in rest) {
      await cart.add(line, cartStore);
    }
    return RepeatAdded(store, missing: repeated.missing);
  }
}
