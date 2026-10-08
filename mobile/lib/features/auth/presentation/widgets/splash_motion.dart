import 'package:flutter/animation.dart';

/// Duraciones de la entrada y la salida del arranque. Mientras la sesión tarda,
/// la moto sigue andando en su sitio (el bucle es del propio Lottie).
abstract final class SplashTiming {
  static const intro = Duration(milliseconds: 1300);
  static const exit = Duration(milliseconds: 650);
}

/// Un cuadro del arranque a partir del avance (0–1) de la entrada y de la
/// salida. Puro: se prueba sin widgets.
///
/// La "a" del arranque nativo se abre en un disco crema; entra la moto por la
/// izquierda y aparece la palabra. Al salir, la moto acelera hacia la derecha y
/// el disco crece hasta cubrir la pantalla.
class SplashFrame {
  const SplashFrame._({
    required this.markOpacity,
    required this.discScale,
    required this.riderX,
    required this.wordOpacity,
    required this.wordY,
    required this.reveal,
  });

  factory SplashFrame.at({required double intro, required double exit}) {
    final grow = Curves.easeOutBack.transform(_span(intro, 0.05, 0.45));
    final arrive = Curves.easeOutCubic.transform(_span(intro, 0.3, 0.75));
    final word = Curves.easeOut.transform(_span(intro, 0.55, 0.9));
    final leave = Curves.easeInCubic.transform(_span(exit, 0, 0.5));
    return SplashFrame._(
      markOpacity: 1 - _span(intro, 0.05, 0.3),
      discScale: grow,
      riderX: -1.2 * (1 - arrive) + 1.3 * leave,
      wordOpacity: word * (1 - _span(exit, 0, 0.4)),
      wordY: 14 * (1 - word),
      reveal: Curves.easeInOutCubic.transform(_span(exit, 0.35, 1)),
    );
  }

  /// La "a" sin pedido del arranque nativo, que se desvanece al abrirse el disco.
  final double markOpacity;

  /// Tamaño del disco crema (0–1, con un pequeño rebote).
  final double discScale;

  /// Posición de la moto en anchos de disco: −1,2 fuera a la izquierda, 0 al
  /// centro, más de 1 fuera a la derecha.
  final double riderX;

  final double wordOpacity;

  /// Desplazamiento vertical de la palabra (px).
  final double wordY;

  /// 0–1: el disco crece hasta cubrir la pantalla.
  final double reveal;

  static double _span(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);
}
