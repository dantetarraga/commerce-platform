import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Fila de la boleta: ícono, qué es, el valor y la acción a la derecha.
class CheckoutInfoRow extends StatelessWidget {
  const CheckoutInfoRow({
    required this.icon,
    required this.caption,
    required this.title,
    required this.action,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.missing = false,
    super.key,
  });

  final IconData icon;

  /// Reemplaza al [icon] (p. ej. el logo del medio de pago).
  final Widget? leading;
  final String caption;
  final String title;
  final String? subtitle;
  final String action;

  /// Marca la fila con "Falta" en rojo.
  final bool missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = context.chaski.danger;
    return Semantics(
      button: true,
      label: '$caption: $title${subtitle == null ? '' : ', $subtitle'}${missing ? ', falta' : ''}',
      hint: action,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tile,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: leading ?? Icon(icon, size: 22, color: missing ? danger : scheme.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Text(caption.toUpperCase(), style: AppTypography.eyebrow(context)),
                          if (missing) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: danger.withValues(alpha: 0.12),
                                borderRadius: const BorderRadius.all(AppRadius.pill),
                              ),
                              child: Text('Falta', style: theme.textTheme.labelSmall?.copyWith(color: danger)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(action, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
