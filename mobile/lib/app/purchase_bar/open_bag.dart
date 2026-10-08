import 'package:apamuy/app/purchase_bar/purchase_bar_controller.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/checkout/checkout.dart';
import 'package:apamuy/features/home/home.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/shared/design_system/components/app_purchase_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Abre la hoja de la bolsa: "Ir a pagar" lleva al checkout y "Explorar",
/// al inicio. La usan la barra de compra y el acceso "Bolsa" de la navegación.
void openBag(BuildContext context) {
  final router = GoRouter.of(context);
  showCartSheet(
    context,
    onCheckout: () => router.pushNamed(CheckoutPage.name).ignore(),
    onExplore: () => router.goNamed(HomePage.name),
  ).ignore();
}

/// Toque en la barra de compra: abre el seguimiento del pedido en curso si la
/// barra lo está mostrando; si no, la bolsa.
void openPurchaseBar(BuildContext context, WidgetRef ref) {
  final order = ref.read(activeOrderProvider).value;
  if (ref.read(purchaseBarProvider).state is PurchaseBarOrder && order != null) {
    context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id}).ignore();
    return;
  }
  openBag(context);
}
