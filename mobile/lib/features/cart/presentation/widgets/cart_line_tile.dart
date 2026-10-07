import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fila de la bolsa: deslizar o "−" en 1 quita; tocar edita la nota.
///
/// Quitar y deshacer los resuelve quien la contiene ([onRemove]): la fila se
/// desmonta al salir y no puede mostrar el aviso de "Deshacer".
class CartLineTile extends StatelessWidget {
  const CartLineTile({required this.line, this.onRemove, this.onDismissed, this.onQuantityChanged, this.onEditNotes, super.key});

  final CartLine line;
  final VoidCallback? onRemove;

  /// Avisa que la salida ya se animó deslizando (antes de [onRemove]).
  final VoidCallback? onDismissed;
  final ValueChanged<Quantity>? onQuantityChanged;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    return Dismissible(
      key: ValueKey('dismiss-${line.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDismissed?.call();
        onRemove?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: chaski.danger.withValues(alpha: 0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quitar', style: theme.textTheme.labelLarge?.copyWith(color: chaski.danger)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.delete_outline_rounded, color: chaski.danger),
          ],
        ),
      ),
      child: Semantics(
        hint: line.notes.isEmpty ? 'Toca para agregar una nota' : 'Toca para editar la nota',
        child: InkWell(
          onTap: onEditNotes,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
            child: Row(
              children: [
                AppNetworkImage(url: line.imageUrl, width: 60, height: 60, borderRadius: AppRadius.tile, fallbackIcon: Icons.fastfood_rounded),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (line.description.isNotEmpty) Text(line.description, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      if (line.notes.isNotEmpty)
                        Text(
                          '“${line.notes}”',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: AppSpacing.xxs),
                      AppPrice(line.total, size: 15),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _LineStepper(
                  quantity: line.quantity,
                  onChanged: onQuantityChanged,
                  onRemove: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stepper compacto: en 1, el "−" se convierte en quitar.
class _LineStepper extends StatelessWidget {
  const _LineStepper({required this.quantity, required this.onChanged, required this.onRemove});

  final Quantity quantity;
  final ValueChanged<Quantity>? onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atOne = !quantity.canDecrement;
    final onChanged = this.onChanged;
    Widget button(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.padded),
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick().ignore();
              onTap();
            },
      icon: Icon(icon, size: 18),
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: const BorderRadius.all(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            atOne ? Icons.delete_outline_rounded : Icons.remove_rounded,
            atOne ? 'Quitar' : 'Quitar uno',
            atOne ? onRemove : (onChanged == null ? null : () => onChanged(quantity.decrement())),
          ),
          SizedBox(
            width: 20,
            child: AnimatedSwitcher(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
              child: Text(
                '${quantity.value}',
                key: ValueKey(quantity.value),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppTypography.tabularFigures),
              ),
            ),
          ),
          button(Icons.add_rounded, 'Agregar uno', quantity.canIncrement && onChanged != null ? () => onChanged(quantity.increment()) : null),
        ],
      ),
    );
  }
}
