import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

enum AppSectionHeaderStyle {
  /// Título de sección de pantalla (`titleLarge`): "Cerca de ti", "Menú".
  title,

  /// Título de grupo dentro de una hoja o formulario (`titleMedium`):
  /// "Elige tu presentación".
  group,

  /// Eyebrow en mayúsculas ("RECIENTES"): agrupa sin gritar.
  eyebrow,
}

/// Encabezado de sección: título (o eyebrow), bajada opcional y una acción a la
/// derecha ([onSeeAll] o [action]). Con acción, el margen derecho se achica.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(
    this.title, {
    this.subtitle,
    this.style = AppSectionHeaderStyle.title,
    this.onSeeAll,
    this.seeAllLabel = 'Ver todo',
    this.action,
    this.padding,
    super.key,
  }) : assert(onSeeAll == null || action == null, 'Usa onSeeAll o action, no ambos');

  /// Eyebrow en mayúsculas con el margen de los grupos de Explorar.
  const AppSectionHeader.eyebrow(
    this.title, {
    this.action,
    this.onSeeAll,
    this.seeAllLabel = 'Ver todo',
    this.padding,
    super.key,
  }) : subtitle = null,
       style = AppSectionHeaderStyle.eyebrow,
       assert(onSeeAll == null || action == null, 'Usa onSeeAll o action, no ambos');

  final String title;
  final String? subtitle;
  final AppSectionHeaderStyle style;

  /// Muestra el enlace [seeAllLabel] ("Ver todo") a la derecha.
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  /// Acción propia a la derecha (botón "Borrar", etiqueta "Obligatorio"…).
  final Widget? action;

  /// Margen propio; por defecto depende de [style] (ver [defaultPadding]).
  final EdgeInsetsGeometry? padding;

  /// Margen por defecto: secciones con aire arriba ([AppSpacing.section]),
  /// grupos y eyebrows más juntos. Con acción, el margen derecho es corto.
  static EdgeInsets defaultPadding(AppSectionHeaderStyle style, {required bool hasAction}) {
    final right = hasAction && style != AppSectionHeaderStyle.group ? AppSpacing.xs : AppSpacing.gutter;
    return switch (style) {
      AppSectionHeaderStyle.title => EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.section, right, AppSpacing.sm),
      AppSectionHeaderStyle.group => EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, right, AppSpacing.sm),
      AppSectionHeaderStyle.eyebrow => EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, right, AppSpacing.xs),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing =
        action ??
        (onSeeAll == null
            ? null
            : TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch)),
                child: Text(
                  seeAllLabel,
                  semanticsLabel: '$seeAllLabel: $title',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ));
    final titleStyle = switch (style) {
      AppSectionHeaderStyle.title => theme.textTheme.titleLarge,
      AppSectionHeaderStyle.group => theme.textTheme.titleMedium,
      AppSectionHeaderStyle.eyebrow => AppTypography.eyebrow(context),
    };

    Widget heading = Semantics(header: true, child: Text(title, style: titleStyle));
    if (subtitle != null) {
      heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          if (style == AppSectionHeaderStyle.title) const SizedBox(height: 2),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      );
    }

    return Padding(
      padding: padding ?? defaultPadding(style, hasAction: trailing != null),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: trailing != null && style == AppSectionHeaderStyle.eyebrow ? AppSpacing.minTouch : 0),
        child: Row(
          crossAxisAlignment: style == AppSectionHeaderStyle.title ? CrossAxisAlignment.end : CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
