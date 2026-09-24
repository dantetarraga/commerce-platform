import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum AppChipVariant {
  /// Activa/desactiva un filtro (varios a la vez).
  filter,

  /// Una opción de un grupo (secciones del menú, tamaños).
  choice,

  /// Sugerencia que dispara una acción (búsquedas populares).
  suggestion,
}

/// Chip de Chaski: píldora gris; seleccionada pasa a tinta (contraste máximo)
/// y, si es filtro, muestra un check.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.variant = AppChipVariant.filter,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final AppChipVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final active = selected && variant != AppChipVariant.suggestion;
    final bg = active ? scheme.inverseSurface : chaski.raised;
    final fg = active ? scheme.onInverseSurface : scheme.onSurface;

    return Semantics(
      button: true,
      selected: variant == AppChipVariant.suggestion ? null : selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: AnimatedContainer(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
              curve: AppMotion.postaOut,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
              decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active && variant == AppChipVariant.filter) ...[
                    Icon(Icons.check_rounded, size: 16, color: fg),
                    const SizedBox(width: 4),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
