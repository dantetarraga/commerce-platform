import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Productos del negocio: marcar agotado lo oculta del menú del cliente.
class MerchantProductsPage extends ConsumerWidget {
  const MerchantProductsPage({required this.storeId, super.key});

  static const name = 'merchantProducts';

  final String storeId;

  Future<void> _toggle(BuildContext context, WidgetRef ref, MerchantProduct product, bool available) async {
    final failure = await ref
        .read(merchantProductsProvider(storeId).notifier)
        .setAvailable(product, available: available);
    if (failure != null && context.mounted) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(merchantProductsProvider(storeId));
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: AsyncValueView(
        value: products,
        onRetry: () => ref.invalidate(merchantProductsProvider(storeId)),
        loading: const Center(child: CircularProgressIndicator()),
        isEmpty: (list) => list.isEmpty,
        empty: const AppEmptyState(title: 'Sin productos', message: 'Todavía no cargamos tu menú.'),
        data: (list) {
          final sections = <String, List<MerchantProduct>>{};
          for (final p in list) {
            (sections[p.section ?? 'Otros'] ??= []).add(p);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
                child: Text(
                  'Apaga lo que se acabó: el cliente no podrá pedirlo hasta que lo vuelvas a prender.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              for (final MapEntry(key: section, value: items) in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xs),
                  child: Text(section, style: theme.textTheme.titleMedium),
                ),
                for (final p in items)
                  SwitchListTile(
                    contentPadding: AppSpacing.screen,
                    title: Text(p.name),
                    subtitle: Text(p.isAvailable ? Formatters.money(p.price) : 'Agotado'),
                    value: p.isAvailable,
                    onChanged: (value) => _toggle(context, ref, p, value),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
