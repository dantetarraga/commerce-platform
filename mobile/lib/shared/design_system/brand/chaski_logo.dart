import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Marca Chaski: un bloque cobalto redondeado, cruzado por el hilo que
/// termina en un nudo lima, + wordmark en Outfit.
class ChaskiLogo extends StatelessWidget {
  const ChaskiLogo({
    this.size = 40,
    this.showWordmark = true,
    this.onDark = false,
    super.key,
  });

  final double size;
  final bool showWordmark;

  /// Sobre fondos cobalto u oscuros: el bloque se invierte (blanco con hilo cobalto).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = onDark ? scheme.onPrimary : scheme.onSurface;
    // Es arte de marca: no escala con el tamaño de texto del sistema.
    return Semantics(
      label: 'Chaski',
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChaskiMark(size: size, inverted: onDark),
            if (showWordmark) ...[
              SizedBox(width: size * 0.26),
              Text(
                'chaski',
                style: TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: size * 0.72,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -size * 0.01,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Solo el símbolo (para íconos, splash y avatar de la app).
class ChaskiMark extends StatelessWidget {
  const ChaskiMark({this.size = 40, this.inverted = false, super.key});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final r = size * 0.28;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inverted ? AppColors.blanco : AppColors.terracota,
          borderRadius: BorderRadius.circular(r),
        ),
        child: CustomPaint(
          painter: _MarkPainter(
            thread: inverted ? AppColors.terracota : AppColors.blanco,
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.thread});

  final Color thread;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // El hilo entra por abajo a la izquierda, dibuja una "c" y sale a un nudo.
    final path = Path()
      ..moveTo(s * 0.14, s * 0.78)
      ..cubicTo(s * 0.30, s * 0.80, s * 0.36, s * 0.70, s * 0.34, s * 0.52)
      ..cubicTo(s * 0.32, s * 0.30, s * 0.56, s * 0.22, s * 0.66, s * 0.36);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = thread
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.085
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        Offset(s * 0.70, s * 0.40),
        s * 0.11,
        Paint()..color = AppColors.hierba,
      );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.thread != thread;
}
