import 'package:flutter/material.dart';

/// Espaciado en base 4.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const gutter = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Separación entre secciones de una pantalla: se separan con aire, no con líneas.
  static const double section = xl;

  /// Margen lateral de las pantallas.
  static const screen = EdgeInsets.symmetric(horizontal: gutter);

  /// Área táctil mínima (accesibilidad).
  static const minTouch = 48.0;
}

/// Radios parejos por tamaño: cuanto más grande la pieza, más redondeada.
abstract final class AppRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const pill = Radius.circular(999);

  /// Chips grandes, miniaturas, logos.
  static const tile = BorderRadius.all(md);

  /// Botones y campos.
  static const button = BorderRadius.all(Radius.circular(14));

  /// Cards, fotos de negocio y producto.
  static const card = BorderRadius.all(Radius.circular(18));

  /// Hojas inferiores.
  static const sheet = BorderRadius.vertical(top: xl);
}

/// Solo dos niveles de sombra; en oscuro la elevación se expresa con superficies.
abstract final class AppShadows {
  static List<BoxShadow> soft(Brightness brightness) => brightness == Brightness.dark
      ? const []
      : const [BoxShadow(color: Color(0x0F16151C), blurRadius: 16, offset: Offset(0, 4))];

  static List<BoxShadow> raised(Brightness brightness) => brightness == Brightness.dark
      ? const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))]
      : const [
          BoxShadow(color: Color(0x0816151C), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x1216151C), blurRadius: 24, offset: Offset(0, 8)),
        ];
}
