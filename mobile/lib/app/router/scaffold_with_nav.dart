import 'package:chaski/app/purchase_bar/open_bag.dart';
import 'package:chaski/app/purchase_bar/purchase_bar_controller.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/cart/cart.dart';
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
      bottomNavigationBar: AppNavigationDock(
        index: shell.currentIndex,
        onSelected: _select,
        bagCount: count,
        bagPulse: pulse,
        onBag: () => openBag(context),
        liveOrder: liveOrder,
        avatar: AppAvatar(imageUrl: user.avatarUrl, initials: user.initials, seed: user.id, size: 28),
      ),
    );
  }
}
