// El painter se lee como una secuencia de capas (cielo, cerros, casas, hilo):
// encadenar todo en cascadas lo haría más difícil de seguir.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Una sola calle de Espinar dibujada con una línea, tres pantallas de ancho.
/// La cámara avanza con [page] (0..2, sigue al dedo):
///
/// - cerros (capa lenta), casas (media) e hilo (al ritmo del dedo): parallax;
/// - el hilo se dibuja hasta donde llegó el usuario y se desanda si vuelve;
/// - una bolsa viaja por el hilo desde el negocio hasta la puerta (paso 2 → 3);
/// - al llegar, el hilo se anuda en la puerta.
///
/// Con [still] (movimiento reducido) se muestra el cuadro del paso sin parallax.
///
/// Va dentro de un bloque `primaryContainer` de radio 26: el cobalto queda
/// para el hilo, las casas son grises neutros y la lima marca los nudos.
class StreetScene extends StatelessWidget {
  const StreetScene({required this.page, required this.pages, this.still = false, super.key});

  final double page;
  final int pages;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final colors = context.chaski;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(26)),
        child: CustomPaint(
          painter: _StreetPainter(
            page: page.clamp(0.0, pages - 1.0),
            pages: pages,
            still: still,
            sky: scheme.primaryContainer,
            hills: Color.alphaBlend(colors.thread.withValues(alpha: 0.08), scheme.primaryContainer),
            houses: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            thread: colors.thread,
            knot: colors.accent,
            ground: scheme.surface,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _StreetPainter extends CustomPainter {
  _StreetPainter({
    required this.page,
    required this.pages,
    required this.still,
    required this.sky,
    required this.hills,
    required this.houses,
    required this.thread,
    required this.knot,
    required this.ground,
  });

  final double page;
  final int pages;
  final bool still;
  final Color sky;
  final Color hills;
  final Color houses;
  final Color thread;
  final Color knot;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseline = h * 0.78;
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);

    // ── Cerros (capa lenta) ───────────────────────────────────────────────
    canvas
      ..save()
      ..translate(-page * w * (still ? 1 : 0.35), 0);
    final hillPath = Path()..moveTo(-w, baseline);
    for (var x = -w; x <= w * (pages + 1); x += w / 2) {
      final peak = h * (0.34 + 0.12 * math.sin(x / w * 2.1));
      hillPath.quadraticBezierTo(x + w / 4, peak, x + w / 2, baseline - h * 0.08);
    }
    hillPath
      ..lineTo(w * (pages + 1), h)
      ..lineTo(-w, h)
      ..close();
    canvas
      ..drawPath(hillPath, Paint()..color = hills)
      ..restore();

    // Suelo.
    canvas.drawRect(Rect.fromLTRB(0, baseline, w, h), Paint()..color = ground.withValues(alpha: 0.6));

    // ── Casas (capa media) ────────────────────────────────────────────────
    final houseStroke = Paint()
      ..color = houses
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..save()
      ..translate(-page * w * (still ? 1 : 0.75), 0);
    for (var i = 0; i < pages * 3 + 2; i++) {
      final x = i * w / 3 - w * 0.05;
      final hw = w * (0.18 + 0.04 * (i % 2));
      final hh = h * (0.22 + 0.06 * ((i * 7) % 3) / 2);
      final house = Path()
        ..moveTo(x, baseline)
        ..lineTo(x, baseline - hh)
        ..lineTo(x + hw / 2, baseline - hh - h * 0.07)
        ..lineTo(x + hw, baseline - hh)
        ..lineTo(x + hw, baseline);
      canvas
        ..drawPath(house, houseStroke)
        ..drawRect(Rect.fromLTWH(x + hw * 0.18, baseline - hh * 0.62, hw * 0.2, hh * 0.22), houseStroke);
    }
    canvas.restore();

    // ── Hilo (al ritmo del dedo) ──────────────────────────────────────────
    canvas
      ..save()
      ..translate(-page * w, 0);
    final storeAt = Offset(w * 0.5, baseline - h * 0.32); // negocio (paso 1)
    final handsAt = Offset(w * 1.5, baseline - h * 0.24); // quien prepara (paso 2)
    final doorAt = Offset(w * 2.5, baseline - h * 0.06); // tu puerta (paso 3)

    // Toldo del negocio y puerta de la casa, dibujados con el mismo hilo.
    final line = Paint()
      ..color = thread
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final awning = Path()
      ..moveTo(storeAt.dx - w * 0.14, storeAt.dy)
      ..lineTo(storeAt.dx + w * 0.14, storeAt.dy);
    for (var k = 0; k < 4; k++) {
      final sx = storeAt.dx - w * 0.14 + k * w * 0.07;
      awning.addArc(Rect.fromLTWH(sx, storeAt.dy - w * 0.035, w * 0.07, w * 0.07), 0, math.pi);
    }
    final door = Path()
      ..moveTo(doorAt.dx - w * 0.07, baseline)
      ..lineTo(doorAt.dx - w * 0.07, baseline - h * 0.26)
      ..lineTo(doorAt.dx + w * 0.07, baseline - h * 0.26)
      ..lineTo(doorAt.dx + w * 0.07, baseline);
    canvas
      ..drawPath(awning, line..color = thread.withValues(alpha: 0.9))
      ..drawPath(door, line);

    // El recorrido completo: nace a la izquierda, rodea el negocio, pasa por
    // las manos que preparan y termina en la puerta.
    final route = Path()
      ..moveTo(-w * 0.1, baseline - h * 0.05)
      ..cubicTo(w * 0.15, baseline - h * 0.05, w * 0.25, storeAt.dy + h * 0.2, storeAt.dx - w * 0.05, storeAt.dy + h * 0.1)
      ..cubicTo(storeAt.dx + w * 0.1, storeAt.dy + h * 0.02, storeAt.dx + w * 0.02, storeAt.dy - h * 0.12, storeAt.dx - w * 0.06, storeAt.dy + h * 0.02)
      ..cubicTo(storeAt.dx - w * 0.1, storeAt.dy + h * 0.1, w * 0.9, baseline - h * 0.02, w * 1.2, baseline - h * 0.1)
      ..cubicTo(w * 1.35, baseline - h * 0.16, handsAt.dx - w * 0.1, handsAt.dy + h * 0.08, handsAt.dx, handsAt.dy)
      ..cubicTo(handsAt.dx + w * 0.1, handsAt.dy - h * 0.08, w * 1.8, baseline - h * 0.02, w * 2.1, baseline - h * 0.06)
      ..cubicTo(w * 2.3, baseline - h * 0.09, doorAt.dx - w * 0.12, doorAt.dy, doorAt.dx, doorAt.dy);

    final metric = route.computeMetrics().first;
    // Hasta dónde llega el hilo según el paso (siempre un poco más allá del centro).
    final reach = still ? (page + 1) / pages : ((page + 0.62) / pages).clamp(0.0, 1.0);
    canvas.drawPath(metric.extractPath(0, metric.length * reach), line..color = thread);

    // Nudos en cada hito ya alcanzado.
    void knotAt(Offset at, double appearAt, double radius) {
      final t = ((reach - appearAt) / 0.06).clamp(0.0, 1.0);
      if (t == 0) return;
      final r = radius * AppMotion.knot.transform(t);
      canvas
        ..drawCircle(at, r, Paint()..color = knot)
        ..drawCircle(
          at,
          r,
          Paint()
            ..color = thread
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
    }

    knotAt(storeAt + Offset(-w * 0.02, h * 0.04), 0.2, 9);
    knotAt(handsAt, 0.5, 9);
    knotAt(doorAt, 0.97, 12);

    // La bolsa viaja por el hilo entre el paso 2 y el 3.
    final travel = (page - 1).clamp(0.0, 1.0);
    if (page >= 0.6) {
      final bagT = (0.52 + travel * 0.44).clamp(0.0, reach);
      final tangent = metric.getTangentForOffset(metric.length * bagT);
      if (tangent != null) _drawBag(canvas, tangent.position - Offset(0, h * 0.05), w * 0.07, thread, knot);
    }
    canvas.restore();
  }

  void _drawBag(Canvas canvas, Offset center, double s, Color stroke, Color fill) {
    final body = RRect.fromRectAndCorners(
      Rect.fromCenter(center: center, width: s, height: s * 0.9),
      topLeft: Radius.circular(s * 0.12),
      topRight: Radius.circular(s * 0.28),
      bottomLeft: Radius.circular(s * 0.12),
      bottomRight: Radius.circular(s * 0.12),
    );
    final handle = Path()
      ..addArc(Rect.fromCenter(center: center - Offset(0, s * 0.45), width: s * 0.5, height: s * 0.5), math.pi, math.pi);
    canvas
      ..drawRRect(body, Paint()..color = fill)
      ..drawRRect(
        body,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      )
      ..drawPath(
        handle,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = ui.StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_StreetPainter old) =>
      old.page != page ||
      old.still != still ||
      old.sky != sky ||
      old.hills != hills ||
      old.houses != houses ||
      old.thread != thread ||
      old.knot != knot ||
      old.ground != ground;
}
