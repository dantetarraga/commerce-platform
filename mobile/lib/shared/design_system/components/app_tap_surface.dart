import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Superficie tocable: el patrón de los mosaicos y tarjetas de portada en una
/// pieza. Semántica de botón, escala leve al presionar ([PressableScale]),
/// fondo [color] con radio [borderRadius] y onda recortada a esa forma.
///
/// Con [semanticLabel] el lector de pantalla lee solo esa frase (el contenido
/// se excluye); sin él, lee los textos del hijo como un único botón.
///
/// ```dart
/// AppTapSurface(
///   semanticLabel: 'Explorar Farmacias',
///   color: context.chaski.card,
///   borderRadius: AppRadius.tileExit,
///   onTap: open,
///   child: SizedBox(height: 120, child: tile),
/// )
/// ```
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
