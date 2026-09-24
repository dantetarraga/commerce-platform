import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/home/home.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/components/app_posta.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posta_provider.g.dart';

/// Lo que la posta muestra + un contador para hacer "saltar" el nudo.
typedef PostaView = ({PostaState state, int pulse});

/// Traduce la bolsa y el pedido en curso a la forma de la posta. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.
@Riverpod(keepAlive: true)
class Posta extends _$Posta {
  var _pulse = 0;
  var _lastCount = 0;

  @override
  PostaView build() {
    final cart = ref.watch(cartControllerProvider).value ?? Cart.empty;
    final order = ref.watch(activeOrderProvider).value;

    // El nudo salta cuando la bolsa recibe algo nuevo.
    if (cart.itemCount > _lastCount) _pulse++;
    _lastCount = cart.itemCount;

    return (state: _stateFor(cart, order), pulse: _pulse);
  }

  PostaState _stateFor(Cart cart, Order? order) {
    if (order != null && order.status != OrderStatus.cancelled && !(order.status == OrderStatus.delivered && order.rating != null)) {
      final minutes = order.minutesLeft(DateTime.now());
      return PostaOrder(
        message: order.headline,
        eta: order.status == OrderStatus.onTheWay && minutes != null ? '$minutes min' : null,
        delivered: order.status == OrderStatus.delivered,
      );
    }
    if (!cart.isEmpty) return PostaCart(count: cart.itemCount, total: cart.total, storeName: cart.store?.name);
    return const PostaHidden();
  }

  /// Toque en la posta: abre el seguimiento del pedido o la bolsa.
  void open(BuildContext context) {
    final router = GoRouter.of(context);
    final order = ref.read(activeOrderProvider).value;
    if (state.state is PostaOrder && order != null) {
      router.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id}).ignore();
      return;
    }
    showCartSheet(
      context,
      onCheckout: () => router.pushNamed(CheckoutPage.name).ignore(),
      onExplore: () => router.goNamed(HomePage.name),
    ).ignore();
  }
}
