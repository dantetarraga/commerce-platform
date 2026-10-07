import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Duraciones de las tres fases del arranque.
abstract final class SplashTiming {
  static const intro = Duration(milliseconds: 1300);
  static const loop = Duration(milliseconds: 1800);
  static const exit = Duration(milliseconds: 650);
}

/// Un cuadro del arranque a partir del avance (0–1) de la entrada, del relevo
/// (`null` si no está corriendo) y de la salida. Puro: se prueba sin widgets.
class SplashFrame {
  SplashFrame._({
    required this.dotOffset,
    required this.dotScale,
    required this.dotOpacity,
    required this.bodyAngle,
    required this.bodyScale,
    required this.contentOpacity,
    required this.contentScale,
    required this.reveal,
    required double intro,
    required double? loop,
  }) : _intro = intro,
       _loopT = loop;

  factory SplashFrame.at({required double intro, required double? loop, required double exit}) {
    var dotOffset = Offset.zero;
    var dotScale = 1.0;
    var dotOpacity = 1.0;
    var angle = 0.0;
    var bodyScale = 1.0;

    if (loop == null) {
      // Entrada: el pedido llega desde arriba a la izquierda, se pasa un poco y se asienta.
      final fly = Curves.easeOutCubic.transform(_span(intro, 0, 0.5));
      final settle = Curves.easeOut.transform(_span(intro, 0.5, 0.62));
      dotOffset = Offset.lerp(Offset.lerp(const Offset(-150, -60), const Offset(4, 0), fly), Offset.zero, settle)!;
      dotScale = _lerp(_lerp(0.8, 1.05, fly), 1, settle);
      dotOpacity = _span(intro, 0, 0.2);
      angle = _keys(intro, const [(0.62, 0), (0.72, -6), (0.88, 2), (1, 0)]);
      bodyScale = _keys(intro, const [(0.62, 1), (0.72, 1.04), (0.88, 1), (1, 1)]);
    } else {
      // Relevo: el pedido sale por la derecha y otro entra por la izquierda.
      if (loop < 0.3) {
        final s = Curves.easeIn.transform(loop / 0.3);
        dotOffset = Offset(90 * s, 0);
        dotOpacity = 1 - s;
      } else if (loop < 0.31) {
        dotOpacity = 0;
      } else if (loop < 0.62) {
        final s = Curves.easeOutCubic.transform((loop - 0.31) / 0.31);
        dotOffset = Offset(-120 * (1 - s), 0);
        dotOpacity = s;
      }
      angle = _keys(loop, const [(0.58, 0), (0.66, -5), (0.78, 1.5), (0.9, 0)]);
    }

    final fade = Curves.easeIn.transform(_span(exit, 0, 0.5));
    return SplashFrame._(
      dotOffset: dotOffset,
      dotScale: dotScale,
      dotOpacity: dotOpacity,
      bodyAngle: angle * math.pi / 180,
      bodyScale: bodyScale,
      contentOpacity: 1 - fade,
      contentScale: 1 + 0.15 * fade,
      reveal: Curves.easeInOutCubic.transform(_span(exit, 0.15, 1)),
      intro: intro,
      loop: loop,
    );
  }

  final Offset dotOffset;
  final double dotScale;
  final double dotOpacity;
  final double bodyAngle;
  final double bodyScale;
  final double contentOpacity;
  final double contentScale;
  final double reveal;
  final double _intro;
  final double? _loopT;

  /// Cada letra salta en cascada cuando la "a" atrapa el pedido.
  double _letterIn(int i) => Curves.easeOutBack.transform(_span(_intro, 0.55 + i * 0.045, 0.85 + i * 0.045));

  double letterOpacity(int i) => _span(_intro, 0.55 + i * 0.045, 0.7 + i * 0.045);

  double letterScale(int i) => 0.6 + 0.4 * _letterIn(i);

  double letterY(int i) {
    final entry = 24 * (1 - _letterIn(i));
    final t = _loopT;
    if (t == null) return entry;
    // Ola: cada letra sube un poco justo después de que llega el pedido.
    final d = (t - (0.62 + i * 0.03)) / 0.075;
    return d.abs() < 1 ? -6 * math.sin((1 - d.abs()) * math.pi / 2) : 0;
  }

  static double _span(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Interpola linealmente entre cuadros clave (tiempo, valor).
  static double _keys(double t, List<(double, double)> keys) {
    if (t <= keys.first.$1) return keys.first.$2;
    for (var i = 1; i < keys.length; i++) {
      final (t1, v1) = keys[i];
      if (t <= t1) {
        final (t0, v0) = keys[i - 1];
        return _lerp(v0, v1, (t - t0) / (t1 - t0));
      }
    }
    return keys.last.$2;
  }
}
