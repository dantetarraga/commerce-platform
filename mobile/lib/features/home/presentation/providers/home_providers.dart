import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/maps/delivery_location.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/home/domain/repeat_order.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/features/products/products.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

sealed class RepeatOutcome {
  const RepeatOutcome();
}

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
    final detail = await ref.read(getStoreDetailProvider).call(order.store.id, near: near);
    final StoreSummary store;
    switch (detail) {
      case Ok(:final value):
        store = value.summary;
      case Err(:final failure):
        return RepeatFailed(order.store.name, failure);
    }
    if (!store.canOrder) return RepeatUnavailable(store);

    final repeated = await RepeatOrder(ref.read(getProductDetailProvider)).call(order, near: near);
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
