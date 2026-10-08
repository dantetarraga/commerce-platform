import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/core/utils/text_scale.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "Volver a pedir": tarjetas con foto, cuántas veces lo pediste y "Repetir".
class RepeatShelf extends StatelessWidget {
  const RepeatShelf({required this.orders, required this.timesByStore, required this.onOpen, required this.onRepeat, super.key});

  final List<Order> orders;

  /// Pedidos entregados por id de negocio.
  final Map<String, int> timesByStore;
  final ValueChanged<Order> onOpen;
  final ValueChanged<Order> onRepeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168 + textScaleExtra(context, max: 30) * 5,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          final times = timesByStore[order.store.id] ?? 1;
          return _RepeatCard(
            order: order,
            eyebrow: times >= 3 ? 'Lo pediste $times veces' : (index == 0 ? 'Tu último pedido' : 'Pediste hace poco'),
            highlight: times >= 3 || index == 0,
            onTap: () => onOpen(order),
            onRepeat: () => onRepeat(order),
          );
        },
      ),
    );
  }
}

class _RepeatCard extends StatelessWidget {
  const _RepeatCard({required this.order, required this.eyebrow, required this.highlight, required this.onTap, required this.onRepeat});

  final Order order;
  final String eyebrow;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = order.lines.map((l) => l.name).join(' + ');
    final total = Formatters.money(order.total);
    return AppTapSurface(
      semanticLabel: '$eyebrow. ${order.store.name}. $items. $total',
      explicitChildNodes: true,
      color: context.apamuy.card,
      onTap: onTap,
      child: SizedBox(
        width: 296,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              AppNetworkImage(
                url: order.store.logoUrl,
                width: 92,
                height: double.infinity,
                borderRadius: AppRadius.exit(18),
                fallbackIcon: Icons.storefront_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: highlight ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(order.store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                    Text(items, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                    const Spacer(),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(total, style: AppTypography.price(context, size: 16))),
                        _RepeatButton(storeName: order.store.name, onPressed: onRepeat),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({required this.storeName, required this.onPressed});

  final String storeName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: 'Repetir pedido de $storeName',
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: scheme.primary,
        borderRadius: AppRadius.button,
        child: InkWell(
          borderRadius: AppRadius.button,
          onTap: onPressed,
          child: Container(
            height: AppSpacing.minTouch,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay_rounded, size: 15, color: scheme.onPrimary),
                const SizedBox(width: 4),
                Text('Repetir', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
