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

/// Esquina de salida: una sola esquina corta, abajo a la izquierda, por donde sale el
/// trazo de Apamuy. Tres tamaños (L 28/8, M 22/6, S 16/5); personas y fotos de portada en círculo.
abstract final class AppRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const pill = Radius.circular(999);

  /// Chips grandes, miniaturas, logos.
  static const tile = BorderRadius.all(md);

  /// Botones, campos, indicadores y etiquetas (S).
  static const button = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(16),
    bottomLeft: Radius.circular(5),
  );

  /// Categorías, buscador y tarjetas medianas (M).
  static const tileExit = BorderRadius.only(
    topLeft: Radius.circular(22),
    topRight: Radius.circular(22),
    bottomRight: Radius.circular(22),
    bottomLeft: Radius.circular(6),
  );

  /// Cards, fotos de negocio y producto (L).
  static const card = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
    bottomRight: Radius.circular(24),
    bottomLeft: Radius.circular(8),
  );

  /// Portadas: solo las esquinas inferiores, con la de salida corta.
  static const hero = BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(36));

  /// Esquina de salida a medida: tres esquinas de radio [r] y la inferior izquierda
  /// corta (~30 % de [r] por defecto; [cut] la fija a mano).
  static BorderRadius exit(double r, {double? cut}) {
    final big = Radius.circular(r);
    return BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomRight: big,
      bottomLeft: Radius.circular(cut ?? (r * 0.3).roundToDouble()),
    );
  }

  /// Cabeceras de pantalla de color (socios): solo las esquinas inferiores,
  /// la de salida corta y la derecha amplia.
  static const header = BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(28));

  /// Hojas inferiores.
  static const sheet = BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28));
}

/// Pocos niveles de sombra; en oscuro la elevación se expresa con superficies.
abstract final class AppShadows {
  static List<BoxShadow> soft(Brightness brightness) =>
      brightness == Brightness.dark ? const [] : const [BoxShadow(color: Color(0x0F2A1A14), blurRadius: 16, offset: Offset(0, 4))];

  static List<BoxShadow> raised(Brightness brightness) => brightness == Brightness.dark
      ? const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))]
      : const [
          BoxShadow(color: Color(0x082A1A14), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x122A1A14), blurRadius: 24, offset: Offset(0, 8)),
        ];

  /// Tarjeta levantada sobre el fondo (comandas, tarjetas destacadas).
  static const List<BoxShadow> lifted = [BoxShadow(color: Color(0x1F2A1A14), blurRadius: 18, offset: Offset(0, 8))];

  /// Perilla o ficha pequeña que se arrastra o se apila (deslizar para confirmar, sellos).
  static const List<BoxShadow> knob = [BoxShadow(color: Color(0x402A1A14), blurRadius: 6, offset: Offset(0, 3))];
}
