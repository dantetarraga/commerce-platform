import 'dart:math' as math;

import 'package:chaski/shared/design_system/brand/brand_logo.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Indicador de carga de la marca: el relevo del arranque en miniatura. El
/// pedido sale de la "a" por la derecha, otro entra por la izquierda y la "a"
/// se mece al recibirlo. Reemplaza a los spinners circulares y barras finas.
///
/// Con movimiento reducido queda quieto (la "a" con su pedido).
class AppLoader extends StatelessWidget {
  const AppLoader({this.size = 24, this.color, this.dot = AppColors.hierba, this.semanticsLabel = 'Cargando', super.key});

  final double size;

  /// Color de la "a"; por defecto el primario.
  final Color? color;
  final Color dot;
  final String? semanticsLabel;

  static const Duration period = AppMotion.pulse;

  @override
  Widget build(BuildContext context) {
    final body = color ?? Theme.of(context).colorScheme.primary;
    Widget frame(double t) => CustomPaint(size: Size.square(size), painter: _relay(t, body));

    final mark = reduceMotionOf(context)
        ? frame(0.7)
        : Animate(onPlay: (c) => c.repeat()).custom(duration: period, builder: (_, t, _) => frame(t));
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel == null,
      child: SizedBox.square(dimension: size, child: mark),
    );
  }

  BrandMarkPainter _relay(double t, Color body) {
    // Offsets en la grilla de 100 del símbolo (el pintor los escala).
    final k = size / 100;
    var dx = 0.0;
    var opacity = 1.0;
    if (t < 0.3) {
      final s = Curves.easeIn.transform(t / 0.3);
      dx = 34 * s;
      opacity = 1 - s;
    } else if (t < 0.34) {
      opacity = 0;
    } else if (t < 0.62) {
      final s = Curves.easeOutCubic.transform((t - 0.34) / 0.28);
      dx = -40 * (1 - s);
      opacity = s;
    }
    return BrandMarkPainter(
      body: body,
      dot: dot,
      dotOffset: Offset(dx * k, 0),
      dotOpacity: opacity,
      angle: _wobble(t) * math.pi / 180,
    );
  }

  /// La "a" se mece al recibir el pedido.
  static double _wobble(double t) {
    const keys = [(0.58, 0.0), (0.66, -8.0), (0.78, 3.0), (0.9, 0.0)];
    if (t <= keys.first.$1 || t >= keys.last.$1) return 0;
    for (var i = 1; i < keys.length; i++) {
      final (t1, v1) = keys[i];
      final (t0, v0) = keys[i - 1];
      if (t <= t1) return v0 + (v1 - v0) * Curves.easeInOut.transform((t - t0) / (t1 - t0));
    }
    return 0;
  }
}
