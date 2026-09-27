import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Firma de la marca: un recorrido continuo con dos giros y dos estaciones.
class ChaskiTrail extends StatelessWidget {
  const ChaskiTrail({this.color = AppColors.terracota, this.progress = 1, this.strokeWidth = 5, super.key});

  final Color color;
  final double progress;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(painter: _TrailPainter(color, progress, strokeWidth), child: const SizedBox.expand()),
    ),
  );
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter(this.color, this.progress, this.strokeWidth);

  final Color color;
  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.8)
      ..lineTo(w * 0.3, h * 0.8)
      ..cubicTo(w * 0.52, h * 0.8, w * 0.32, h * 0.25, w * 0.54, h * 0.25)
      ..lineTo(w * 0.9, h * 0.25);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint..color = color.withValues(alpha: 0.2));
    final metric = path.computeMetrics().first;
    canvas
      ..drawPath(metric.extractPath(0, metric.length * progress.clamp(0, 1)), paint..color = color)
      ..drawCircle(Offset(w * 0.08, h * 0.8), strokeWidth * 1.2, Paint()..color = color)
      ..drawCircle(Offset(w * 0.9, h * 0.25), strokeWidth * 1.6, paint..strokeWidth = strokeWidth * 0.6);
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) => color != oldDelegate.color || progress != oldDelegate.progress || strokeWidth != oldDelegate.strokeWidth;
}
