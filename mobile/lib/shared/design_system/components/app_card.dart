import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum AppCardVariant {
  /// Bloque tonal sin borde ni sombra: agrupa sin "encajonar".
  flat,

  /// Superficie con sombra suave: lo que debe destacar (máximo uno por vista).
  raised,

  /// Contenedor para foto, recortado con el radio de card.
  media,
}

/// Contenedor genérico. Se usa poco: la jerarquía se construye con espacio y
/// tipografía, no con cajas.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.flat,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color color, BorderRadius radius, List<BoxShadow> shadow) = switch (variant) {
      AppCardVariant.flat => (context.chaski.raised, AppRadius.card, const <BoxShadow>[]),
      AppCardVariant.raised => (theme.colorScheme.surface, AppRadius.card, AppShadows.soft(theme.brightness)),
      AppCardVariant.media => (context.chaski.raised, AppRadius.card, const <BoxShadow>[]),
    };

    Widget card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: Material(
        color: color,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: variant == AppCardVariant.media ? EdgeInsets.zero : padding, child: child),
        ),
      ),
    );
    if (onTap != null) card = PressableScale(child: card);
    return semanticLabel == null ? card : Semantics(label: semanticLabel, button: onTap != null, child: card);
  }
}
