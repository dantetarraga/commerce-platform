import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/home/presentation/pages/home_page.dart';
import 'package:chaski/features/home/presentation/providers/home_providers.dart';
import 'package:chaski/features/home/presentation/widgets/open_store.dart';
import 'package:chaski/features/home/presentation/widgets/repeat_shelf.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Volver a pedir": oculta si no hay historial.
class RepeatRow extends ConsumerWidget {
  const RepeatRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(recentOrdersByStoreProvider).value ?? const [];
    if (orders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('Volver a pedir'),
        RepeatShelf(
          orders: orders,
          timesByStore: ref.watch(deliveredCountByStoreProvider),
          onOpen: (order) => openStore(context, order.store.id),
          onRepeat: (order) => repeatOrder(context, ref, order),
        ),
      ],
    );
  }
}

/// "Repetir": pone el pedido en la bolsa y la abre; cualquier otro final es un aviso.
Future<void> repeatOrder(BuildContext context, WidgetRef ref, Order order) async {
  final router = GoRouter.of(context);
  final outcome = await ref
      .read(repeatOrderControllerProvider.notifier)
      .run(
        order,
        confirmReplace: (current, incoming) async =>
            context.mounted && await confirmReplaceCart(context, current: current, incoming: incoming),
      );
  if (!context.mounted) return;
  switch (outcome) {
    case RepeatFailed(:final storeName):
      AppToast.show(context, 'No pudimos cargar $storeName. Intenta de nuevo.', kind: AppToastKind.error);
    case RepeatUnavailable(:final store):
      AppToast.show(context, cannotOrderMessage(store));
      openStore(context, store.id, coverUrl: store.coverUrl);
    case RepeatNothingLeft(:final store):
      AppToast.show(context, 'Lo de ese pedido ya no está disponible. Mira qué hay hoy.');
      openStore(context, store.id, coverUrl: store.coverUrl);
    case RepeatCancelled():
      break;
    case RepeatAdded(:final store, :final missing):
      HapticFeedback.lightImpact().ignore();
      AppToast.show(
        context,
        missing == 0
            ? 'Tu pedido de ${store.name} va en tu bolsa'
            : 'Agregamos lo disponible; $missing ${missing == 1 ? 'producto ya no está' : 'productos ya no están'}',
        kind: AppToastKind.success,
      );
      showCartSheet(
        context,
        onCheckout: () => router.pushNamed(CheckoutPage.name).ignore(),
        onExplore: () => router.goNamed(HomePage.name),
      ).ignore();
  }
}
