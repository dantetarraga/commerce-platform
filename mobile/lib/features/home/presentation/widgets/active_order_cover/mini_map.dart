import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Mapa ilustrado del pedido activo: calles, la ruta con la doble curva de la
/// marca, el negocio, la casa y la moto en [progress] (0 a 1, no es GPS).
class MiniMap extends StatelessWidget {
  const MiniMap({required this.progress, required this.showRider, required this.logoUrl, super.key});

  final double progress;
  final bool showRider;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _MiniMapPainter(
        base: context.chaski.card,
        street: scheme.primaryContainer,
        route: scheme.primary,
        casing: scheme.outlineVariant,
      ),
      child: _MiniMapPins(progress: progress, showRider: showRider, logoUrl: logoUrl),
    );
  }
}

Path _miniRoute(Size s) => Path()
  ..moveTo(s.width * 0.12, s.height * 0.76)
  ..lineTo(s.width * 0.42, s.height * 0.76)
  ..cubicTo(s.width * 0.58, s.height * 0.76, s.width * 0.56, s.height * 0.27, s.width * 0.7, s.height * 0.27)
  ..lineTo(s.width * 0.86, s.height * 0.27);

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({required this.base, required this.street, required this.route, required this.casing});

  final Color base;
  final Color street;
  final Color route;
  final Color casing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final streets = Paint()
      ..color = street
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    for (final y in [0.27, 0.76]) {
      canvas.drawLine(Offset(-10, size.height * y), Offset(size.width + 10, size.height * y), streets);
    }
    for (final x in [0.2, 0.57, 0.86]) {
      canvas.drawLine(Offset(size.width * x, -10), Offset(size.width * x, size.height + 10), streets);
    }
    canvas.drawLine(Offset(size.width * 0.3, size.height + 10), Offset(size.width * 0.72, -10), streets);
    final path = _miniRoute(size);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = casing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        path,
        Paint()
          ..color = route
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_MiniMapPainter old) => old.base != base || old.street != street || old.route != route || old.casing != casing;
}

class _MiniMapPins extends StatelessWidget {
  const _MiniMapPins({required this.progress, required this.showRider, required this.logoUrl});

  final double progress;
  final bool showRider;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final metric = _miniRoute(size).computeMetrics().first;
        final rider = metric.getTangentForOffset(metric.length * progress)?.position ?? Offset.zero;
        return Stack(
          children: [
            _Pin(
              at: Offset(size.width * 0.12, size.height * 0.76),
              size: 38,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.chaski.accent, width: 3)),
                child: AppNetworkImage(url: logoUrl, borderRadius: const BorderRadius.all(Radius.circular(19)), fallbackIcon: Icons.storefront_rounded),
              ),
            ),
            _Pin(
              at: Offset(size.width * 0.86, size.height * 0.27),
              size: 34,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(Icons.home_rounded, size: 16, color: scheme.onPrimary),
              ),
            ),
            if (showRider)
              _Pin(
                at: rider,
                size: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: scheme.surface, width: 3),
                  ),
                  child: Icon(Icons.moped_rounded, size: 18, color: scheme.onPrimary),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Marca de [size] centrada en [at].
class _Pin extends StatelessWidget {
  const _Pin({required this.at, required this.size, required this.child});

  final Offset at;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Positioned(left: at.dx - size / 2, top: at.dy - size / 2, width: size, height: size, child: child);
}
