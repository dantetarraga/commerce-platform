import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/shared/design_system/components/app_purchase_bar.dart';
import 'package:apamuy/shared/design_system/components/app_receipt_slot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_bar_controller.g.dart';

/// Lo que la barra de compra muestra + un contador para hacer "saltar" el nudo.
typedef PurchaseBarView = ({PurchaseBarState state, int pulse});

/// Traduce la bolsa y el pedido en curso a la barra de compra. El pedido activo
/// tiene prioridad; uno entregado y ya calificado deja de mostrarse.
@Riverpod(keepAlive: true)
PurchaseBarView purchaseBar(Ref ref) {
  final cart = ref.watch(cartControllerProvider).value ?? Cart.empty;
  final order = ref.watch(activeOrderProvider).value;
  return (state: purchaseBarStateFor(cart, order, DateTime.now()), pulse: ref.watch(purchaseBarPulseProvider));
}

/// Cuenta las veces que la bolsa recibió algo nuevo (el nudo salta). Escucha la
/// bolsa en vez de compararla en un `build`, así recalcular la barra no tiene efectos.
@Riverpod(keepAlive: true)
class PurchaseBarPulse extends _$PurchaseBarPulse {
  @override
  int build() {
    ref.listen(cartControllerProvider.select((cart) => cart.value?.itemCount ?? 0), (previous, next) {
      if (next > (previous ?? 0)) state++;
    });
    return 0;
  }
}

/// La boleta del último producto agregado; la imprime la barra que esté a la vista.
@Riverpod(keepAlive: true)
class LastAdded extends _$LastAdded {
  @override
  PurchaseReceipt? build() {
    ref.listen(cartControllerProvider.select((cart) => cart.value), (previous, next) {
      if (next == null) return;
      final receipt = receiptFor(previous, next, id: (state?.id ?? 0) + 1, at: DateTime.now());
      if (receipt != null) state = receipt;
    });
    return null;
  }
}

/// Qué entró a la bolsa entre [before] y [after]: una línea nueva o más unidades
/// de una que ya estaba. `null` si nada creció (se quitó o se editó una nota).
PurchaseReceipt? receiptFor(Cart? before, Cart after, {required int id, required DateTime at}) {
  final previous = {for (final line in before?.lines ?? const <CartLine>[]) line.id: line.quantity.value};
  for (final line in after.lines.reversed) {
    final added = line.quantity.value - (previous[line.id] ?? 0);
    if (added <= 0) continue;
    return PurchaseReceipt(
      id: id,
      at: at,
      title: '$added × ${line.name}',
      detail: line.description.isEmpty ? null : line.description,
      price: line.unitPrice * added,
    );
  }
  return null;
}

PurchaseBarState purchaseBarStateFor(Cart cart, Order? order, DateTime now) {
  if (order != null && order.status != OrderStatus.cancelled && !(order.status == OrderStatus.delivered && order.rating != null)) {
    final minutes = order.minutesLeft(now);
    return PurchaseBarOrder(
      message: order.headline,
      eta: order.status == OrderStatus.onTheWay && minutes != null ? '$minutes min' : null,
      delivered: order.status == OrderStatus.delivered,
      stage: OrderProgressRail.stageOf(order.status),
    );
  }
  if (!cart.isEmpty) return PurchaseBarCart(count: cart.itemCount, total: cart.total, storeName: cart.store?.name);
  return const PurchaseBarHidden();
}
