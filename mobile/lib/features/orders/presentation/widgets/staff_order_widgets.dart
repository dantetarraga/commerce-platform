import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/domain/staff_order.dart';
import 'package:chaski/features/orders/presentation/order_status_labels.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "recién" · "hace 3 min" · "hace 1 h" · "7:02 am" (si pasó más de un día).
String staffTimeAgo(DateTime at, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return 'recién';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return Formatters.clock(at);
}

/// Cabecera de un pedido para socios: código, estado y hace cuánto entró.
class StaffOrderHeader extends StatelessWidget {
  const StaffOrderHeader({required this.order, this.trailing, super.key});

  final StaffOrder order;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final fresh = order.status == OrderStatus.received;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              order.order.code,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: fresh ? theme.colorScheme.primaryContainer : context.chaski.raised,
                borderRadius: AppRadius.tile,
              ),
              child: Text(
                order.status.partnerLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fresh ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text('Recibido ${staffTimeAgo(order.order.placedAt)}', style: muted),
      ],
    );
  }
}
