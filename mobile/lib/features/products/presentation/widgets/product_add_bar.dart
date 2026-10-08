import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/core/utils/text_scale.dart';
import 'package:apamuy/features/products/domain/entities/product_selection.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/quantity_stepper.dart';
import 'package:flutter/material.dart';

/// Barra fija del detalle: por qué no se puede agregar (si aplica), cantidad y
/// "Agregar · total".
class ProductAddBar extends StatelessWidget {
  const ProductAddBar({
    required this.selection,
    required this.open,
    required this.adding,
    required this.onQuantityChanged,
    required this.onAdd,
    super.key,
  });

  final ProductSelection selection;
  final bool open;
  final bool adding;
  final ValueChanged<Quantity> onQuantityChanged;
  final VoidCallback onAdd;

  String? get _hint {
    if (!open) return 'Está cerrado ahora. Programa tu pedido desde el negocio y lo agregas.';
    if (!selection.product.isAvailable) return 'Este producto se agotó por hoy.';
    if (selection.needsVariant) return 'Elige un tamaño.';
    final missing = selection.missingRequiredOptions;
    if (missing.isNotEmpty) return 'Falta elegir: ${missing.map((o) => o.name).join(', ')}.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _hint;
    final canTry = open && selection.product.isAvailable;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          for (final s in AppShadows.soft(theme.brightness)) BoxShadow(color: s.color, blurRadius: s.blurRadius, offset: Offset(0, -s.offset.dy)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                curve: AppMotion.arrive,
                alignment: Alignment.bottomCenter,
                child: hint == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(hint, style: theme.textTheme.bodySmall),
                        ),
                      ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final quantity = QuantityStepper(quantity: selection.quantity, onChanged: onQuantityChanged, enabled: canTry);
                  final add = _AddButton(total: Formatters.money(selection.total), enabled: canTry, valid: selection.isValid, loading: adding, onAdd: onAdd);
                  if (constraints.maxWidth < 340 && isLargeText(context, limit: 19)) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Cantidad', style: theme.textTheme.labelLarge)),
                            quantity,
                          ],
                        ),
                        const SizedBox(height: 8),
                        add,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      quantity,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: add),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Agregar · total"; el total cambia con una transición corta.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.total,
    required this.enabled,
    required this.valid,
    required this.loading,
    required this.onAdd,
  });

  final String total;
  final bool enabled;
  final bool valid;
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Incompleto: se ve más suave pero responde (lleva al grupo que falta).
    final bg = enabled ? (valid ? scheme.primary : scheme.primary.withValues(alpha: 0.55)) : context.apamuy.raised;
    final fg = enabled ? scheme.onPrimary : scheme.onSurfaceVariant;
    final reduce = reduceMotionOf(context);
    final style = theme.textTheme.labelLarge?.copyWith(color: fg, fontSize: 16, fontWeight: FontWeight.w800);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Agregar a la bolsa, $total',
      onTap: enabled && !loading ? onAdd : null,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: AppRadius.button,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !loading ? onAdd : null,
          child: SizedBox(
            height: 56,
            child: Center(
              child: loading
                  ? AppLoader(size: 22, color: fg)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Agregar · ', style: style),
                        AnimatedSwitcher(
                          duration: reduce ? Duration.zero : AppMotion.quick,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            total,
                            key: ValueKey(total),
                            style: style?.copyWith(fontFeatures: AppTypography.tabularFigures),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
