import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/pages/merchant_products_page.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Cocina abierta · recibiendo": pausar deja de mostrar el negocio abierto.
class StoreSwitch extends ConsumerStatefulWidget {
  const StoreSwitch({required this.store, this.compact = false, this.named = false, super.key});

  final MerchantStore store;
  final bool compact;

  /// Con varios negocios, el título es el nombre de cada uno.
  final bool named;

  @override
  ConsumerState<StoreSwitch> createState() => _StoreSwitchState();
}

class _StoreSwitchState extends ConsumerState<StoreSwitch> with PartnerActionRunner {
  Future<void> _toggle(bool accepting) =>
      run(() => ref.read(merchantStoresProvider.notifier).setAccepting(widget.store, accepting: accepting));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final on = store.isAcceptingOrders;
    final title = widget.named
        ? store.name
        : !on
        ? 'Tienda en pausa'
        : widget.compact
        ? 'Tienda abierta'
        : 'Tienda abierta · recibiendo';
    final message = !store.isOpenNow
        ? 'Fuera de tu horario de atención'
        : !on
        ? 'Actívala cuando estés listo'
        : widget.compact
        ? 'Recibiendo pedidos'
        : 'Los clientes ven tu negocio abierto';
    return PartnerStatusPill(title: title, message: message, value: on, busy: busy, onChanged: _toggle);
  }
}

/// Con varios negocios, una píldora por cada uno y el acceso a su carta.
class StoreSwitches extends ConsumerWidget {
  const StoreSwitches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
    child: AsyncValueView(
      value: ref.watch(merchantStoresProvider),
      compactError: true,
      onRetry: () => ref.invalidate(merchantStoresProvider),
      loading: const PartnerStatusPillSkeleton(),
      data: (list) => Column(
        children: [
          for (final store in list)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                children: [
                  StoreSwitch(store: store, named: true),
                  TextButton.icon(
                    onPressed: () => context.pushNamed(MerchantProductsPage.name, pathParameters: {'storeId': store.id}),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text('Carta de ${store.name}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
