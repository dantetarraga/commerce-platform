import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Lo que se pidió, como en una comanda. Va dentro de un ticket ([TicketSection]);
/// [dense] es la versión del repartidor (texto mediano, sin descripciones).
class StaffOrderLines extends StatelessWidget {
  const StaffOrderLines({
    required this.order,
    this.title,
    this.prices = true,
    this.dense = false,
    super.key,
  });

  final Order order;

  /// Eyebrow opcional arriba de las líneas ("LO QUE LLEVAS").
  final String? title;
  final bool prices;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = (dense ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(fontWeight: FontWeight.w700);
    final qty = item?.copyWith(color: scheme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) Text(title!, style: AppTypography.eyebrow(context)),
        for (final line in order.lines) ...[
          const SizedBox(height: 6),
          if (prices)
            LeaderRow(
              leading: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('${line.quantity}×', style: qty),
              ),
              label: Text(line.name, style: item),
              value: Text(Formatters.money(line.total), style: item?.copyWith(fontFeatures: AppTypography.tabularFigures)),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('${line.quantity}×', style: qty),
                ),
                Expanded(child: Text(line.name, style: item)),
              ],
            ),
          if (!dense && line.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(line.description, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          if (line.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 3),
              child: StaffNoteChip('“${line.notes}”'),
            ),
        ],
        if (order.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: StaffNoteChip('Nota: ${order.notes}'),
          ),
      ],
    );
  }
}

/// Nota del cliente resaltada ("sin ají"), con la esquina de salida.
class StaffNoteChip extends StatelessWidget {
  const StaffNoteChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.exit(7, cut: 2)),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Pie de la comanda: "Efectivo · paga con S/ 50.00 ······ S/ 45.00".
/// Va dentro de un ticket (usa [LeaderRow]).
class StaffOrderPayment extends StatelessWidget {
  const StaffOrderPayment({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${order.payment.collectLabel}, total ${spokenMoney(order.total)}',
      excludeSemantics: true,
      child: LeaderRow(
        label: Text(
          order.payment.collectLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        value: Text(Formatters.money(order.total), style: AppTypography.price(context)),
      ),
    );
  }
}
