import 'package:apamuy/apps/customer/shell/purchase_bar/open_bag.dart';
import 'package:apamuy/apps/customer/shell/purchase_bar/purchase_bar_controller.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo lo que la barra muestra: un cambio de precio en la bolsa o de estado
    // dentro de un pedido en curso no reconstruye el shell.
    final count = ref.watch(cartControllerProvider.select((cart) => cart.value?.itemCount ?? 0));
    final liveOrder = ref.watch(activeOrderProvider.select((order) => order.value?.isActive ?? false));
    final pulse = ref.watch(purchaseBarProvider.select((view) => view.pulse));
    final user = ref.watch(
      authSessionProvider.select((session) {
        final u = session.value;
        return (avatarUrl: u?.avatarUrl, initials: u?.initials, id: u?.id);
      }),
    );
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppReceiptSlot(
        receipt: ref.watch(lastAddedProvider),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inicio y Pedidos ya muestran el pedido arriba; en las demás pestañas va fijo aquí.
            if (liveOrder && shell.currentIndex != 0 && shell.currentIndex != 2) const _OrderStrip(),
            AppNavigationDock(
              index: shell.currentIndex,
              onSelected: _select,
              bagCount: count,
              bagPulse: pulse,
              onBag: () => openBag(context),
              liveOrder: liveOrder,
              avatar: AppAvatar(imageUrl: user.avatarUrl, initials: user.initials, seed: user.id, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

/// El pedido en curso fijo sobre el menú, con su barra de tramos. Escucha la barra
/// por su cuenta: un cambio de estado del pedido no reconstruye el shell.
class _OrderStrip extends ConsumerWidget {
  const _OrderStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseBarProvider.select((view) => view.state));
    if (state is! PurchaseBarOrder) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: AppPurchaseBar(state: state, onTap: () => openPurchaseBar(context, ref)),
    );
  }
}
