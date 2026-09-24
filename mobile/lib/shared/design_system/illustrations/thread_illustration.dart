
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Escenas dibujadas con una sola línea (el hilo) y nudos ichu.
///
/// Es el único "personaje" de Chaski: no hay mascotas ni ilustraciones 3D. Las
/// escenas se definen en un lienzo de 200 × 140 y se escalan al tamaño pedido.
enum ThreadScene {
  /// Bolsa vacía (carrito sin productos).
  emptyBag,

  /// Hilo cortado (sin conexión).
  cut,

  /// Nudo enredado (error).
  tangle,

  /// Lupa (sin resultados).
  search,

  /// Nudo atado (éxito, pedido confirmado).
  knot,

  /// Casa con el nudo en la puerta (dirección, entregado).
  door,

  /// Recibo / lista (sin pedidos todavía).
  receipt,
}

/// Dibuja una [ThreadScene]. El hilo se traza de principio a fin al montarse y
/// los nudos "saltan" cuando el trazo pasa por ellos. Con movimiento reducido
/// aparece ya dibujada.
class ThreadIllustration extends StatefulWidget {
  const ThreadIllustration(this.scene, {this.size = 160, this.animate = true, super.key});

  final ThreadScene scene;
  final double size;
  final bool animate;

  @override
  State<ThreadIllustration> createState() => _ThreadIllustrationState();
}

class _ThreadIllustrationState extends State<ThreadIllustration> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ThreadIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene && widget.animate && !reduceMotionOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chaski;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.7,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: ThreadPainter(
              scene: threadSceneData(widget.scene),
              progress: AppMotion.postaOut.transform(_controller.value),
              thread: colors.thread,
              knot: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Geometría de una escena: el trazo y los nudos (posición + en qué fracción
/// del trazo aparecen).
class ThreadSceneData {
  const ThreadSceneData(this.path, this.knots);

  final Path path;
  final List<({Offset at, double t, double radius})> knots;
}

ThreadSceneData threadSceneData(ThreadScene scene) => switch (scene) {
  ThreadScene.emptyBag => ThreadSceneData(
    Path()
      ..moveTo(8, 120)
      ..lineTo(52, 120)
      ..lineTo(60, 54)
      ..lineTo(80, 54)
      ..cubicTo(80, 28, 120, 28, 120, 54)
      ..lineTo(140, 54)
      ..lineTo(148, 120)
      ..lineTo(52, 120)
      ..moveTo(148, 120)
      ..cubicTo(165, 120, 170, 112, 192, 112),
    const [],
  ),
  ThreadScene.cut => ThreadSceneData(
    Path()
      ..moveTo(8, 86)
      ..cubicTo(40, 60, 60, 110, 86, 78)
      ..lineTo(92, 70)
      ..moveTo(108, 72)
      ..lineTo(114, 64)
      ..cubicTo(140, 36, 160, 92, 192, 66),
    const [(at: Offset(92, 70), t: 0.48, radius: 3.5), (at: Offset(108, 72), t: 0.55, radius: 3.5)],
  ),
  ThreadScene.tangle => ThreadSceneData(
    Path()
      ..moveTo(8, 100)
      ..cubicTo(40, 100, 60, 90, 80, 70)
      ..cubicTo(100, 40, 130, 60, 110, 82)
      ..cubicTo(90, 104, 70, 70, 100, 56)
      ..cubicTo(130, 44, 140, 90, 112, 92)
      ..cubicTo(96, 94, 104, 70, 124, 76)
      ..cubicTo(150, 84, 160, 100, 192, 100),
    const [(at: Offset(104, 74), t: 0.6, radius: 7)],
  ),
  ThreadScene.search => ThreadSceneData(
    Path()
      ..moveTo(8, 118)
      ..cubicTo(30, 118, 40, 100, 62, 98)
      ..lineTo(84, 82)
      ..addOval(Rect.fromCircle(center: const Offset(106, 62), radius: 28))
      ..moveTo(128, 80)
      ..cubicTo(150, 96, 170, 118, 192, 118),
    const [],
  ),
  ThreadScene.knot => ThreadSceneData(
    Path()
      ..moveTo(8, 96)
      ..cubicTo(50, 96, 70, 96, 88, 76)
      ..cubicTo(104, 56, 128, 64, 116, 84)
      ..cubicTo(104, 102, 84, 84, 100, 70)
      ..cubicTo(116, 56, 140, 96, 192, 96),
    const [(at: Offset(102, 78), t: 0.62, radius: 11)],
  ),
  ThreadScene.door => ThreadSceneData(
    Path()
      ..moveTo(8, 120)
      ..lineTo(60, 120)
      ..lineTo(60, 64)
      ..lineTo(100, 30)
      ..lineTo(140, 64)
      ..lineTo(140, 120)
      ..lineTo(112, 120)
      ..lineTo(112, 88)
      ..lineTo(88, 88)
      ..lineTo(88, 120)
      ..moveTo(140, 120)
      ..lineTo(192, 120),
    const [(at: Offset(100, 104), t: 0.85, radius: 6)],
  ),
  ThreadScene.receipt => ThreadSceneData(
    Path()
      ..moveTo(8, 120)
      ..lineTo(64, 120)
      ..lineTo(64, 28)
      ..lineTo(136, 28)
      ..lineTo(136, 120)
      ..lineTo(124, 112)
      ..lineTo(112, 120)
      ..lineTo(100, 112)
      ..lineTo(88, 120)
      ..lineTo(76, 112)
      ..lineTo(64, 120)
      ..moveTo(78, 52)
      ..lineTo(122, 52)
      ..moveTo(78, 70)
      ..lineTo(110, 70)
      ..moveTo(78, 88)
      ..lineTo(116, 88)
      ..moveTo(136, 120)
      ..lineTo(192, 120),
    const [(at: Offset(122, 52), t: 0.62, radius: 4)],
  ),
};

/// Pinta el trazo parcial (según [progress]) y los nudos ya alcanzados.
/// Público para reutilizarlo en el onboarding y el seguimiento.
class ThreadPainter extends CustomPainter {
  ThreadPainter({
    required this.scene,
    required this.progress,
    required this.thread,
    required this.knot,
    this.canvasSize = const Size(200, 140),
    this.strokeWidth = 3,
  });

  final ThreadSceneData scene;
  final double progress;
  final Color thread;
  final Color knot;
  final Size canvasSize;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / canvasSize.width).clamp(0.0, size.height / canvasSize.height);
    canvas
      ..save()
      ..translate((size.width - canvasSize.width * scale) / 2, (size.height - canvasSize.height * scale) / 2)
      ..scale(scale);

    final stroke = Paint()
      ..color = thread
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale.clamp(0.6, 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(partialPath(scene.path, progress), stroke);

    for (final k in scene.knots) {
      final appear = ((progress - k.t) / 0.12).clamp(0.0, 1.0);
      if (appear == 0) continue;
      final r = k.radius * AppMotion.knot.transform(appear);
      canvas
        ..drawCircle(k.at, r, Paint()..color = knot)
        ..drawCircle(k.at, r, stroke..strokeWidth = strokeWidth * 0.8 / scale.clamp(0.6, 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ThreadPainter old) =>
      old.progress != progress || old.thread != thread || old.knot != knot || old.scene != scene;
}

/// Porción inicial de [path] (todas sus sub-trayectorias en orden) hasta la
/// fracción [t] de su largo total.
Path partialPath(Path path, double t) {
  if (t >= 1) return path;
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
  var remaining = total * t.clamp(0.0, 1.0);
  final out = Path();
  for (final m in metrics) {
    if (remaining <= 0) break;
    out.addPath(m.extractPath(0, remaining.clamp(0.0, m.length)), Offset.zero);
    remaining -= m.length;
  }
  return out;
}
