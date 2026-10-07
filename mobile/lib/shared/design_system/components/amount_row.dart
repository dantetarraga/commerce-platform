import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/app_price.dart';
import 'package:chaski/shared/design_system/components/app_ticket.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

enum AmountRowKind {
  /// Línea normal (subtotal, envío, propina): texto atenuado.
  regular,

  /// Descuento: "− S/ 3.00" en verde.
  discount,

  /// Total: etiqueta y monto en negrita, el monto en display.
  total,
}

/// Fila de monto con cifras tabulares. Con [leader] usa la línea punteada de la
/// boleta (solo dentro de un ticket); con [freeLabel], el cero se muestra como ese texto.
class AmountRow extends StatelessWidget {
  const AmountRow({
    required this.label,
    required this.amount,
    this.kind = AmountRowKind.regular,
    this.leader = false,
    this.freeLabel,
    this.style,
    this.padding = const EdgeInsets.symmetric(vertical: 2),
    super.key,
  });

  const AmountRow.discount({
    required this.label,
    required this.amount,
    this.leader = false,
    this.style,
    this.padding = const EdgeInsets.symmetric(vertical: 2),
    super.key,
  }) : kind = AmountRowKind.discount,
       freeLabel = null;

  const AmountRow.total({
    required this.label,
    required this.amount,
    this.leader = false,
    this.style,
    this.padding = const EdgeInsets.symmetric(vertical: 2),
    super.key,
  }) : kind = AmountRowKind.total,
       freeLabel = null;

  final String label;
  final Money amount;
  final AmountRowKind kind;
  final bool leader;

  /// Texto para monto cero (p. ej. "Gratis" en el envío).
  final String? freeLabel;

  /// Estilo base de la fila (etiqueta y monto); el tipo lo ajusta.
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = context.chaski.success;
    final free = freeLabel != null && amount.isZero;

    final base = style ?? theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final (TextStyle? labelStyle, TextStyle? amountStyle) = switch (kind) {
      AmountRowKind.regular => (base, base?.copyWith(fontFeatures: AppTypography.tabularFigures)),
      AmountRowKind.discount => (base, base?.copyWith(color: success, fontFeatures: AppTypography.tabularFigures)),
      AmountRowKind.total => (
        (style ?? theme.textTheme.titleSmall)?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        style?.copyWith(fontWeight: FontWeight.w800, fontFeatures: AppTypography.tabularFigures) ?? AppTypography.price(context, size: 16),
      ),
    };
    final value = free
        ? freeLabel!
        : kind == AmountRowKind.discount
        ? '− ${Formatters.money(amount)}'
        : Formatters.money(amount);
    final spoken = free ? freeLabel! : '${kind == AmountRowKind.discount ? 'menos ' : ''}${spokenMoney(amount)}';

    final labelText = Text(label, style: labelStyle);
    final valueText = Text(value, style: free ? amountStyle?.copyWith(color: success) : amountStyle, textAlign: TextAlign.right);

    return Semantics(
      label: '$label, $spoken',
      excludeSemantics: true,
      child: Padding(
        padding: padding,
        child: leader
            ? LeaderRow(label: labelText, value: valueText)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: labelText),
                  valueText,
                ],
              ),
      ),
    );
  }
}
