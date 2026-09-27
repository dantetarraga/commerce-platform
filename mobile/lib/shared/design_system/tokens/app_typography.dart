import 'package:flutter/material.dart';

/// Tipografía Chaski: títulos amables y redondos, interfaz silenciosa.
///
/// - **Outfit** (display): títulos, nombres de negocio y precios. Geométrica y
///   abierta; se usa en 700 con espaciado casi normal para que respire.
/// - **Plus Jakarta Sans** (UI): todo lo demás.
///
/// Ambas van empaquetadas en `assets/fonts` (sin descarga en tiempo de
/// ejecución: la app debe verse bien con red irregular).
abstract final class AppTypography {
  static const display = 'Outfit';
  static const ui = 'Jakarta';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Escala de texto de la app sobre la base de Material 3.
  static TextTheme textTheme(Color ink, Color muted) {
    TextStyle d(double size, double height, FontWeight weight, double tracking) => TextStyle(
      fontFamily: display,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: size * tracking,
      color: ink,
    );
    TextStyle u(double size, double height, FontWeight weight, {double tracking = 0, Color? color}) => TextStyle(
      fontFamily: ui,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color ?? ink,
    );

    return TextTheme(
      displayLarge: d(48, 50, FontWeight.w800, -0.035),
      displayMedium: d(40, 42, FontWeight.w800, -0.03),
      displaySmall: d(34, 36, FontWeight.w800, -0.025),
      headlineLarge: d(30, 36, FontWeight.w700, -0.015),
      headlineMedium: d(26, 32, FontWeight.w700, -0.01),
      headlineSmall: d(22, 28, FontWeight.w700, -0.01),
      titleLarge: d(20, 26, FontWeight.w700, -0.005),
      titleMedium: d(17, 22, FontWeight.w700, 0),
      titleSmall: u(15, 20, FontWeight.w700),
      bodyLarge: u(16, 24, FontWeight.w500),
      bodyMedium: u(15, 22, FontWeight.w500),
      bodySmall: u(13, 18, FontWeight.w500, color: muted),
      labelLarge: u(15, 20, FontWeight.w700),
      labelMedium: u(13, 16, FontWeight.w700, tracking: 0.26),
      labelSmall: u(11, 14, FontWeight.w700, tracking: 0.4),
    );
  }

  /// Precios: display con cifras tabulares para que las columnas se alineen.
  static TextStyle price(BuildContext context, {double size = 20}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0,
      color: theme.colorScheme.onSurface,
      fontFeatures: _tabular,
    );
  }

  /// Etiquetas en mayúsculas tipo "eyebrow" (secciones, pasos).
  static TextStyle eyebrow(BuildContext context) => TextStyle(
    fontFamily: ui,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
    height: 1.3,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static const List<FontFeature> tabularFigures = _tabular;
}
