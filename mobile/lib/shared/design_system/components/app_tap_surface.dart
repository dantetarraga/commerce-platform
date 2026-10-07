import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Superficie tocable de mosaicos y tarjetas: semántica de botón, escala al
/// presionar y onda recortada a [borderRadius]. Con [semanticLabel] solo se lee esa frase.
class AppTapSurface extends StatelessWidget {
  const AppTapSurface({
    required this.child,
    required this.onTap,
    this.color = Colors.transparent,
    this.borderRadius = AppRadius.card,
    this.semanticLabel,
    this.explicitChildNodes = false,
    this.pressScale = 0.97,
    this.clip = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Fondo de la superficie; transparente por defecto (p. ej. sobre una foto).
  final Color color;
  final BorderRadius borderRadius;

  /// Frase completa para lectores de pantalla (reemplaza la del contenido).
  final String? semanticLabel;

  /// Deja que los hijos con semántica propia (p. ej. un favorito) se lean
  /// aparte, como en las cards de negocio.
  final bool explicitChildNodes;

  /// Escala al presionar; `1` la desactiva.
  final double pressScale;

  /// Recorta el contenido a [borderRadius] (fotos de borde a borde).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    Widget surface = Material(
      color: color,
      borderRadius: borderRadius,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        excludeFromSemantics: true,
        child: child,
      ),
    );
    if (onTap != null && pressScale != 1) surface = PressableScale(scale: pressScale, child: surface);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: semanticLabel != null && !explicitChildNodes,
      explicitChildNodes: explicitChildNodes,
      child: surface,
    );
  }
}
