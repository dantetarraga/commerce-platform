import 'package:chaski/app/purchase_bar/purchase_bar_controller.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/home/home.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cinco accesos: Inicio · Buscar · Pedidos · Bolsa · Tú. La bolsa no es una pestaña
/// sino la hoja del carrito, con su contador; el pedido en curso marca "Pedidos".
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _select(int branch) {
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  void _openBag(BuildContext context) {
    final router = GoRouter.of(context);
    showCartSheet(
      context,
      onCheckout: () => router.pushNamed(CheckoutPage.name).ignore(),
      onExplore: () => router.goNamed(HomePage.name),
    ).ignore();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).value?.itemCount ?? 0;
    final order = ref.watch(activeOrderProvider).value;
    final pulse = ref.watch(purchaseBarControllerProvider.select((view) => view.pulse));
    final user = ref.watch(authSessionProvider).value;
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppNavigationDock(
        index: shell.currentIndex,
        onSelected: _select,
        bagCount: count,
        bagPulse: pulse,
        onBag: () => _openBag(context),
        liveOrder: order != null && order.isActive,
        avatar: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.initials, seed: user?.id, size: 28),
      ),
    );
  }
}
