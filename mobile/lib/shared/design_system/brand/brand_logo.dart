import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

const brandName = 'Apamuy';

/// Logo de Apamuy: la "a" de una sola panza con el pedido (punto verde) adentro,
/// + la palabra "apamuy" en Outfit.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 40, this.showWordmark = true, this.onDark = false, super.key});

  /// Alto del símbolo; la palabra se ajusta a él.
  final double size;
  final bool showWordmark;

  /// Sobre terracota u otros fondos oscuros: símbolo y palabra en papel.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Es arte de marca: no escala con el tamaño de texto del sistema.
    return Semantics(
      label: brandName,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: size, color: onDark ? AppColors.papel : scheme.primary),
            if (showWordmark) ...[
              SizedBox(width: size * 0.18),
              Text(
                'apamuy',
                style: TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: size * 0.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -size * 0.012,
                  color: onDark ? AppColors.papel : scheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Solo el símbolo: la "a" y el pedido. [dot] cambia el color del pedido (ocre en Socios).
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 40, this.color, this.dot = AppColors.hierba, super.key});

  final double size;
  final Color? color;
  final Color dot;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: BrandMarkPainter(body: color ?? Theme.of(context).colorScheme.primary, dot: dot),
    ),
  );
}

/// Dibuja la "a" sobre una grilla de 100 × 100. [dotOffset] y [dotScale] mueven
/// el pedido (lo usa la animación de arranque).
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    required this.body,
    required this.dot,
    this.dotOffset = Offset.zero,
    this.dotScale = 1,
    this.dotOpacity = 1,
    this.drawDot = true,
    this.angle = 0,
  });

  final Color body;
  final Color dot;
  final Offset dotOffset;
  final double dotScale;
  final double dotOpacity;
  final bool drawDot;

  /// Giro de la "a" (radianes) alrededor del centro de su panza.
  final double angle;

  /// Centro del pedido en la grilla de 100.
  static const dotCenter = Offset(46, 54);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas
      ..save()
      ..scale(k);
    if (angle != 0) {
      canvas
        ..translate(dotCenter.dx, dotCenter.dy)
        ..rotate(angle)
        ..translate(-dotCenter.dx, -dotCenter.dy);
    }
    final bowl = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: dotCenter, radius: 26))
      ..addOval(Rect.fromCircle(center: dotCenter, radius: 13));
    final paint = Paint()
      ..color = body
      ..isAntiAlias = true;
    canvas
      ..drawPath(bowl, paint)
      ..drawRRect(RRect.fromLTRBR(60, 28, 75, 80, const Radius.circular(7.5)), paint);
    if (drawDot && dotOpacity > 0) {
      canvas.drawCircle(
        dotCenter + dotOffset / k,
        7 * dotScale,
        Paint()..color = dot.withValues(alpha: dot.a * dotOpacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.body != body ||
      old.dot != dot ||
      old.dotOffset != dotOffset ||
      old.dotScale != dotScale ||
      old.dotOpacity != dotOpacity ||
      old.drawDot != drawDot ||
      old.angle != angle;
}
