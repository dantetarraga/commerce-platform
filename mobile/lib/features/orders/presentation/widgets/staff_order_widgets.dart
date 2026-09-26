import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/domain/staff_order.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "hace 3 min" · "hace 1 h" · "7:02" (si pasó más de un día).
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
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Row(
      children: [
        Text(order.order.code, style: theme.textTheme.titleLarge?.copyWith(fontFeatures: AppTypography.tabularFigures)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${order.status.staffLabel} · ${staffTimeAgo(order.order.placedAt)}',
            style: muted,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Lo que se pidió, con las notas del cliente resaltadas.
class StaffOrderLines extends StatelessWidget {
  const StaffOrderLines({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final note = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text('${line.quantity}×', style: theme.textTheme.titleSmall),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: theme.textTheme.bodyLarge),
                      if (line.description.isNotEmpty) Text(line.description, style: muted),
                      if (line.notes.isNotEmpty) Text('“${line.notes}”', style: note),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (order.notes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xxs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
            child: Text('Nota: ${order.notes}', style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

/// "Total S/ 45.00 · Efectivo, paga con S/ 50.00".
class StaffOrderPayment extends StatelessWidget {
  const StaffOrderPayment({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = order.payment;
    final change = payment is CashPayment && payment.changeFor != null
        ? ', paga con ${Formatters.money(payment.changeFor!)}'
        : '';
    return Row(
      children: [
        Expanded(
          child: Text(
            '${payment.label}$change',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Text(Formatters.money(order.total), style: theme.textTheme.titleMedium),
      ],
    );
  }
}
