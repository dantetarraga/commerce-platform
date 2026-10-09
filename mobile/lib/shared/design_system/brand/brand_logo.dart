import 'dart:math' as math;

import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

const brandName = 'Apamuy';

/// Sombras del logo, como en un afiche chicha: ocre y, debajo, hierba.
/// En tamaños chicos (o con [layered] en falso, como en Socios) queda solo la ocre.
List<Shadow> brandShadows(double fontSize, {bool layered = true, double ratio = 0.055}) {
  final step = math.max(1.5, fontSize * ratio);
  return [
    Shadow(color: AppColors.ocre, offset: Offset(step, step)),
    if (layered && fontSize >= 32) Shadow(color: AppColors.hierba, offset: Offset(step * 2, step * 2)),
  ];
}

/// Cuánto ocupan [shadows] a la derecha y abajo de la letra.
double _depth(List<Shadow> shadows) => shadows.isEmpty ? 0 : shadows.last.offset.dx;

/// Logo de Apamuy: "APAMUY" en Bungee con sombras desplazadas.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 26, this.onDark = false, super.key});

  /// Tamaño de la letra.
  final double size;

  /// Sobre terracota u otros fondos oscuros: letras en papel.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.papel : Theme.of(context).colorScheme.primary;
    final shadows = brandShadows(size);
    return Semantics(
      label: brandName,
      excludeSemantics: true,
      // Es arte de marca: no escala con el tamaño de texto del sistema.
      child: MediaQuery.withNoTextScaling(
        child: Padding(
          padding: EdgeInsets.only(right: _depth(shadows), bottom: _depth(shadows)),
          child: Text(
            'APAMUY',
            maxLines: 1,
            style: TextStyle(fontFamily: AppTypography.brand, fontSize: size, height: 1, color: color, shadows: shadows),
          ),
        ),
      ),
    );
  }
}

/// La "A" de la marca centrada en un cuadrado de [size]: ícono, arranque y sello.
class BrandGlyph extends StatelessWidget {
  const BrandGlyph({required this.size, this.color = AppColors.papel, this.shadows = true, this.layered = true, super.key});

  final double size;
  final Color color;

  /// Sin sombras para el ícono monocromo de Android.
  final bool shadows;

  /// Las dos sombras (cliente) o solo la ocre (Socios).
  final bool layered;

  /// Letra respecto del cuadrado; el ícono y el arranque nativo usan la misma proporción.
  static const scale = 0.62;

  @override
  Widget build(BuildContext context) {
    final fontSize = size * scale;
    // Más finas que en la palabra: en una sola letra grande pesan más.
    final shadows = this.shadows ? brandShadows(fontSize, layered: layered, ratio: 0.045) : const <Shadow>[];
    final depth = _depth(shadows);
    return SizedBox.square(
      dimension: size,
      child: Center(
        // Corre la letra la mitad de la sombra para que el conjunto quede centrado.
        child: Transform.translate(
          offset: Offset(-depth / 2, -depth / 2),
          child: Text(
            'A',
            textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
            style: TextStyle(
              fontFamily: AppTypography.brand,
              fontSize: fontSize,
              height: 1,
              color: color,
              shadows: shadows,
            ),
          ),
        ),
      ),
    );
  }
}

/// La "A" en una baldosa, como el ícono de la app. En Socios es tinta (papel en oscuro).
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 44, this.background, this.foreground, this.layered = true, super.key});

  final double size;
  final Color? background;
  final Color? foreground;
  final bool layered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background ?? scheme.primary,
            borderRadius: BorderRadius.circular(size * 0.27),
          ),
          child: BrandGlyph(size: size, color: foreground ?? AppColors.papel, layered: layered),
        ),
      ),
    );
  }
}

/// Marca de Apamuy Socios: la baldosa, "APAMUY SOCIOS" y el modo ([role]: "TU NEGOCIO", "REPARTO").
class PartnerBrand extends StatelessWidget {
  const PartnerBrand({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$brandName Socios · $role',
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(background: scheme.onSurface, foreground: scheme.surface, layered: false),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APAMUY SOCIOS',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: AppTypography.brand,
                      fontSize: 18,
                      height: 1,
                      color: scheme.onSurface,
                      shadows: brandShadows(18),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
