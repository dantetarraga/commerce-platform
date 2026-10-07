import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/components/app_purchase_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_bar_controller.g.dart';

/// Lo que la barra de compra muestra + un contador para hacer "saltar" el nudo.
typedef PurchaseBarView = ({PurchaseBarState state, int pulse});

/// Traduce la bolsa y el pedido en curso a la forma de la barra de compra. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse. Abrirla es cosa de la UI: ver `openPurchaseBar`.
@Riverpod(keepAlive: true)
PurchaseBarView purchaseBar(Ref ref) {
  final cart = ref.watch(cartControllerProvider).value ?? Cart.empty;
  final order = ref.watch(activeOrderProvider).value;
  return (state: purchaseBarStateFor(cart, order, DateTime.now()), pulse: ref.watch(purchaseBarPulseProvider));
}

/// Cuenta las veces que la bolsa recibió algo nuevo: el nudo de la barra salta
/// cada vez que cambia. Escucha la bolsa en vez de compararla dentro de un
/// `build`, así recalcular la barra no tiene efectos secundarios.
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

/// Estado de la barra para [cart] y el pedido en curso [order].
PurchaseBarState purchaseBarStateFor(Cart cart, Order? order, DateTime now) {
  if (order != null && order.status != OrderStatus.cancelled && !(order.status == OrderStatus.delivered && order.rating != null)) {
    final minutes = order.minutesLeft(now);
    return PurchaseBarOrder(
      message: order.headline,
      eta: order.status == OrderStatus.onTheWay && minutes != null ? '$minutes min' : null,
      delivered: order.status == OrderStatus.delivered,
    );
  }
  if (!cart.isEmpty) return PurchaseBarCart(count: cart.itemCount, total: cart.total, storeName: cart.store?.name);
  return const PurchaseBarHidden();
}
