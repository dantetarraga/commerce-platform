import 'dart:math' as math;

import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Mapa esquemático del barrio: manzanas grises, la ruta del negocio a tu
/// puerta (sólida lo recorrido, punteada lo que falta) y tres marcadores
/// propios: negocio, repartidor y casa.
///
/// Cuando se integre un mapa real, este widget se reemplaza sin tocar la
/// pantalla de seguimiento.
class RouteMap extends StatefulWidget {
  const RouteMap({required this.progress, this.showCourier = true, this.height, super.key});

  /// 0 = saliendo del negocio, 1 = en tu puerta.
  final double progress;

  /// Antes de que haya repartidor solo se ven negocio, casa y la ruta.
  final bool showCourier;

  /// `null` = ocupa todo el alto disponible.
  final double? height;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> with SingleTickerProviderStateMixin {
  late final _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draw.isAnimating || _draw.value == 1) return;
    if (reduceMotionOf(context)) {
      _draw.value = 1;
    } else {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chaski = context.chaski;
    final percent = (widget.progress.clamp(0.0, 1.0) * 100).round();
    final map = TweenAnimationBuilder<double>(
      tween: Tween(end: widget.progress.clamp(0.0, 1.0)),
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.story,
      curve: AppMotion.postaOut,
      builder: (context, p, _) => AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => CustomPaint(
          painter: _RoutePainter(
            reveal: AppMotion.postaOut.transform(_draw.value),
            progress: p,
            showCourier: widget.showCourier,
            ground: chaski.raised,
            block: scheme.surfaceContainerHigh,
            route: chaski.thread,
            marker: scheme.primary,
            onMarker: scheme.onPrimary,
            surface: scheme.surface,
            ink: scheme.inverseSurface,
            onInk: scheme.onInverseSurface,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    return Semantics(
      label: widget.showCourier ? 'Mapa de la ruta. Tu pedido va $percent % del camino.' : 'Mapa de la ruta del negocio a tu casa.',
      child: ExcludeSemantics(
        child: widget.height == null ? map : SizedBox(height: widget.height, child: map),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.reveal,
    required this.progress,
    required this.showCourier,
    required this.ground,
    required this.block,
    required this.route,
    required this.marker,
    required this.onMarker,
    required this.surface,
    required this.ink,
    required this.onInk,
  });

  final double reveal;
  final double progress;
  final bool showCourier;
  final Color ground;
  final Color block;
  final Color route;
  final Color marker;
  final Color onMarker;
  final Color surface;
  final Color ink;
  final Color onInk;

  // Plano en un lienzo de 280×250 que se escala para cubrir (como `slice`).
  static const _w = 280.0;
  static const _h = 250.0;
  static const _blocks = [
    Rect.fromLTWH(10, 30, 80, 60),
    Rect.fromLTWH(105, 30, 70, 80),
    Rect.fromLTWH(190, 30, 80, 50),
    Rect.fromLTWH(10, 105, 80, 70),
    Rect.fromLTWH(105, 125, 70, 55),
    Rect.fromLTWH(190, 95, 80, 85),
    Rect.fromLTWH(10, 190, 80, 60),
    Rect.fromLTWH(105, 195, 70, 55),
    Rect.fromLTWH(190, 195, 80, 55),
    Rect.fromLTWH(-80, 30, 75, 220),
    Rect.fromLTWH(285, 30, 75, 220),
    Rect.fromLTWH(-80, -60, 440, 75),
  ];
  static const _store = Offset(50, 97);
  static const _home = Offset(230, 187);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final scale = math.max(size.width / _w, size.height / _h);
    // Se centra el plano un poco más arriba: abajo lo tapa la hoja.
    final dx = (size.width - _w * scale) / 2;
    final dy = (size.height - _h * scale) * 0.3;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final blocks = Paint()..color = block;
    for (final r in _blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), blocks);
    }

    final path = Path()
      ..moveTo(_store.dx, _store.dy)
      ..lineTo(97, 97)
      ..lineTo(97, 187)
      ..lineTo(_home.dx, _home.dy);
    final metric = path.computeMetrics().first;
    final visible = metric.length * reveal;
    final done = (metric.length * (showCourier ? progress : 0)).clamp(0.0, visible);

    // Recorrido: hilo sólido.
    canvas.drawPath(
      metric.extractPath(0, done),
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Por recorrer: puntos.
    final dots = Paint()..color = route;
    for (var d = done + 9; d < visible; d += 9) {
      final t = metric.getTangentForOffset(d);
      if (t != null) canvas.drawCircle(t.position, 2, dots);
    }

    // Negocio: círculo claro con borde cobalto.
    canvas
      ..drawCircle(_store, 13, Paint()..color = surface)
      ..drawCircle(
        _store,
        13,
        Paint()
          ..color = marker
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    _icon(canvas, Icons.storefront_rounded, _store, marker);

    // Casa: círculo tinta.
    canvas.drawCircle(_home, 13, Paint()..color = ink);
    _icon(canvas, Icons.home_rounded, _home, onInk);

    // Repartidor: círculo cobalto con halo.
    final tangent = metric.getTangentForOffset(done);
    if (showCourier && tangent != null && reveal > 0.2) {
      final at = tangent.position;
      canvas
        ..drawCircle(at, 20, Paint()..color = marker.withValues(alpha: 0.18))
        ..drawCircle(at, 13, Paint()..color = marker);
      _icon(canvas, Icons.moped_rounded, at, onMarker);
    }
    canvas.restore();
  }

  void _icon(Canvas canvas, IconData icon, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 14, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.reveal != reveal ||
      old.progress != progress ||
      old.showCourier != showCourier ||
      old.route != route ||
      old.ground != ground ||
      old.block != block;
}
