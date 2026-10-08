import 'dart:math' as math;

import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Indicador de carga corto (botones, campos): tres puntos que saltan en ola.
/// Para esperas de pantalla completa está `AppWaitLoader`. Con movimiento
/// reducido quedan quietos.
class AppLoader extends StatelessWidget {
  const AppLoader({this.size = 24, this.color, this.semanticsLabel = 'Cargando', super.key});

  /// Alto del indicador; el ancho es 1,6 veces.
  final double size;

  /// Color de los puntos; por defecto el primario.
  final Color? color;
  final String? semanticsLabel;

  static const Duration period = Duration(milliseconds: 1000);

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    final dot = size * 0.3;
    Widget frame(double t) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: dot * 0.6),
          _Dot(size: dot, color: tint, hop: _hop(t - i * 0.15)),
        ],
      ],
    );

    final dots = reduceMotionOf(context)
        ? frame(-1)
        : Animate(onPlay: (c) => c.repeat()).custom(duration: period, builder: (_, t, _) => frame(t));
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel == null,
      child: SizedBox(width: size * 1.6, height: size, child: dots),
    );
  }

  /// 0 en reposo, 1 en lo alto. Cada punto salta en el primer 60 % de su vuelta.
  static double _hop(double t) {
    final phase = t % 1;
    if (phase > 0.6) return 0;
    return math.sin(phase / 0.6 * math.pi);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, required this.hop});

  final double size;
  final Color color;
  final double hop;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(0, -hop * size * 0.8),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: color.a * (0.55 + 0.45 * hop)), shape: BoxShape.circle),
    ),
  );
}
