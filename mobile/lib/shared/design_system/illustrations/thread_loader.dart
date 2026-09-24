import 'dart:math' as math;

import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Indicador de carga de Chaski: una cuerda que ondula y un nudo que la
/// recorre, como la posta que viaja. Reemplaza al spinner genérico en cargas
/// de pantalla completa (splash, confirmar pedido).
///
/// Con movimiento reducido, la cuerda queda quieta y el nudo "respira".
class ThreadLoader extends StatefulWidget {
  const ThreadLoader({this.width = 120, this.color, this.knotColor, this.semanticLabel = 'Cargando', super.key});

  final double width;
  final Color? color;
  final Color? knotColor;
  final String semanticLabel;

  @override
  State<ThreadLoader> createState() => _ThreadLoaderState();
}

class _ThreadLoaderState extends State<ThreadLoader> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chaski;
    final reduce = reduceMotionOf(context);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: widget.width,
        height: 24,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _LoaderPainter(
              t: reduce ? 0.5 : _controller.value,
              breathe: reduce ? (math.sin(_controller.value * math.pi * 2) + 1) / 2 : 0,
              thread: widget.color ?? colors.thread,
              knot: widget.knotColor ?? colors.accent,
              still: reduce,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  const _LoaderPainter({
    required this.t,
    required this.breathe,
    required this.thread,
    required this.knot,
    required this.still,
  });

  final double t;
  final double breathe;
  final Color thread;
  final Color knot;
  final bool still;

  double _y(double x, Size size) {
    final phase = still ? 0 : t * math.pi * 2;
    return size.height / 2 + math.sin(x / size.width * math.pi * 3 - phase) * size.height * 0.22;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, _y(0, size));
    for (var x = 2.0; x <= size.width; x += 2) {
      path.lineTo(x, _y(x, size));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = thread
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // El nudo avanza de izquierda a derecha con aceleración suave.
    final progress = still ? 0.5 : AppMotion.postaOut.transform(t);
    final x = size.width * progress;
    final center = Offset(x, _y(x, size));
    final r = 6 + breathe * 1.5;
    canvas
      ..drawCircle(center, r, Paint()..color = knot)
      ..drawCircle(
        center,
        r,
        Paint()
          ..color = thread
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.t != t || old.breathe != breathe || old.thread != thread || old.knot != knot || old.still != still;
}
