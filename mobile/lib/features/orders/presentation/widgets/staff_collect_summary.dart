import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Lo que cobra el repartidor al entregar: la sección de cobro del ticket (usa
/// [LeaderRow]) o, con [StaffCollectSummary.compact], una sola fila.
class StaffCollectSummary extends StatelessWidget {
  const StaffCollectSummary({required this.order, this.title = 'COBRA AL ENTREGAR', super.key}) : _compact = false;

  const StaffCollectSummary.compact({required this.order, super.key}) : title = '', _compact = true;

  final Order order;
  final String title;
  final bool _compact;

  @override
  Widget build(BuildContext context) => _compact ? _CompactCollect(order: order) : _FullCollect(order: order, title: title);
}

class _FullCollect extends StatelessWidget {
  const _FullCollect({required this.order, required this.title});

  final Order order;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant);
    final change = order.changeDue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.eyebrow(context))),
            Text(order.payment.label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        AmountRow(label: 'Pedido', amount: order.itemsSubtotal, leader: true, style: row),
        AmountRow(label: 'Envío', amount: order.deliveryFee, leader: true, style: row),
        const SizedBox(height: 4),
        // El total va grande: es lo que el repartidor lee de un vistazo al cobrar.
        Semantics(
          label: 'Total, ${spokenMoney(order.total)}',
          excludeSemantics: true,
          child: LeaderRow(
            label: Text('Total', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            value: Text(Formatters.money(order.total), style: AppTypography.price(context, size: 28)),
          ),
        ),
        if (change != null && !change.isZero) ...[
          const SizedBox(height: 6),
          Text(
            Formatters.keepCurrencyTogether(
              'Paga con ${Formatters.money(order.total + change)} · lleva ${Formatters.money(change)} de vuelto',
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

class _CompactCollect extends StatelessWidget {
  const _CompactCollect({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      decoration: BoxDecoration(color: context.apamuy.raised, borderRadius: AppRadius.tile),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Cobras · ${order.payment.collectLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(Formatters.money(order.total), style: AppTypography.price(context)),
        ],
      ),
    );
  }
}
