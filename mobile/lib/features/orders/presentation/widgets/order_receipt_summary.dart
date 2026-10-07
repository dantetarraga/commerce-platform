import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Detalle plegable del pedido: productos, montos, dirección y vuelto.
class OrderReceiptSummary extends StatelessWidget {
  const OrderReceiptSummary({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = order.itemCount;
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Detalle del pedido · ${order.code}', style: theme.textTheme.titleMedium),
        subtitle: Text(
          '$count ${count == 1 ? 'producto' : 'productos'} · ${Formatters.money(order.total)} · ${order.payment.label}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          for (final line in order.lines) _LineRow(line: line),
          const SizedBox(height: AppSpacing.sm),
          AmountRow(label: 'Envío', amount: order.deliveryFee),
          if (!order.discount.isZero) AmountRow.discount(label: 'Descuento', amount: order.discount),
          if (!order.tip.isZero) AmountRow(label: 'Propina', amount: order.tip),
          AmountRow.total(label: 'Total', amount: order.total),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Entregar en', value: '${order.addressTitle} · ${order.addressStreet}'),
          if (order.payment case CashPayment(:final changeFor?)) AmountRow(label: 'Vuelto de', amount: changeFor),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Text('${line.quantity}×', style: theme.textTheme.labelLarge)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: theme.textTheme.bodyMedium),
                if (line.description.isNotEmpty) Text(line.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(Formatters.money(line.total), style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppTypography.tabularFigures)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
