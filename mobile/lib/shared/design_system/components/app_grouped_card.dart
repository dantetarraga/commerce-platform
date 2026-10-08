import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Tarjeta con borde fino que agrupa filas ([AppGroupedRow]) separadas por
/// líneas. Perfil, ayuda de un pedido, ajustes.
class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({required this.children, this.color, super.key});

  final List<Widget> children;

  /// Fondo; por defecto `surface`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: line),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de lista agrupada: ícono, título, subtítulo opcional, [trailing] y
/// chevron. Mide al menos 56 (48 en [AppGroupedRow.link], la versión suelta).
class AppGroupedRow extends StatelessWidget {
  const AppGroupedRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    super.key,
  }) : _link = false;

  /// Enlace suelto (fuera de una [AppGroupedCard]): ícono simple, 48 de alto y
  /// onda con radio [AppRadius.tile].
  const AppGroupedRow.link({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.padding = EdgeInsets.zero,
    super.key,
  }) : _link = true;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Sin [onTap] la fila es informativa (sin onda ni chevron).
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry padding;
  final bool _link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leading = _link
        ? Icon(icon, size: 20, color: scheme.onSurfaceVariant)
        : Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: context.apamuy.raised, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: scheme.onSurface),
          );
    final titleText = Text(title, style: _link ? theme.textTheme.labelLarge : theme.textTheme.titleSmall);
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: _link ? AppRadius.tile : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _link ? AppSpacing.minTouch : 56),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: subtitle == null
                      ? titleText
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleText,
                            Text(subtitle!, style: theme.textTheme.bodySmall),
                          ],
                        ),
                ),
                ?trailing,
                if (showChevron && onTap != null) ...[
                  if (!_link) const SizedBox(width: AppSpacing.xxs),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
