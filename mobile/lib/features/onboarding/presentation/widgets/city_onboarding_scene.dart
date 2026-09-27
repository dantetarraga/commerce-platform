import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Una única composición se desplaza con el dedo; las estaciones no se reinician.
class CityOnboardingScene extends StatelessWidget {
  const CityOnboardingScene({required this.page, required this.still, super.key});

  final double page;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final p = still ? page.roundToDouble() : page;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: ColoredBox(
          color: AppColors.terracota50,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _CityBackdrop(page: p)),
                    ),
                  ),
                  Positioned(
                    left: -p * 24,
                    right: -40 + p * 12,
                    top: h * 0.12,
                    bottom: h * 0.08,
                    child: ChaskiTrail(progress: 0.35 + p / 3, strokeWidth: 7),
                  ),
                  for (final (i, icon, color, ink, label) in [
                    (0, Icons.storefront_rounded, AppColors.hierbaSoft, AppColors.tinta, 'DESCUBRE'),
                    (1, Icons.shopping_bag_outlined, AppColors.terracota, AppColors.blanco, 'ELIGE'),
                    (2, Icons.door_front_door_outlined, AppColors.hierba, AppColors.blanco, 'RECIBE'),
                  ])
                    Positioned(
                      left: w * 0.5 - 50 + (i - p) * w * 0.68,
                      top: h * 0.24 + (i - p).abs().clamp(0, 1) * 24,
                      child: Transform.rotate(
                        angle: still ? 0 : (i - p) * 0.12,
                        child: Opacity(
                          opacity: (1 - (i - p).abs() * 0.4).clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 108,
                                decoration: BoxDecoration(color: color, borderRadius: AppRadius.card),
                                child: Icon(icon, size: 54, color: ink),
                              ),
                              const SizedBox(height: 14),
                              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.tinta, letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    top: 18,
                    child: Text('DE AQUÍ. PARA TI.', style: AppTypography.eyebrow(context).copyWith(color: AppColors.terracota700)),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 16,
                    child: Text('0${page.round() + 1} / 03', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.tinta)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Silueta de comercios con distinta profundidad; la cámara sigue al gesto.
class _CityBackdrop extends CustomPainter {
  const _CityBackdrop({required this.page});

  final double page;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.88;
    for (var i = -1; i < 8; i++) {
      final x = i * 86.0 - page * 28;
      final height = 55.0 + (i % 3) * 24;
      final rect = Rect.fromLTWH(x, baseline - height, 70, height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = const Color(0xFFEFD9CC));
      final roof = Path()
        ..moveTo(x - 4, rect.top + 8)
        ..lineTo(x + 35, rect.top - 16)
        ..lineTo(x + 74, rect.top + 8);
      canvas.drawPath(
        roof,
        Paint()
          ..color = const Color(0xFFDDBBA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      for (var j = 0; j < 3; j++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 10 + j * 18, rect.top + 18, 9, 14), const Radius.circular(3)),
          Paint()..color = i.isEven ? AppColors.blanco : AppColors.hierbaSoft,
        );
      }
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 27, baseline - 27, 18, 27), const Radius.circular(4)), Paint()..color = AppColors.terracota700);
    }
    final sun = Offset(size.width * 0.81 - page * 8, size.height * 0.22);
    canvas.drawCircle(sun, 21, Paint()..color = AppColors.terracota300);
  }

  @override
  bool shouldRepaint(_CityBackdrop oldDelegate) => oldDelegate.page != page;
}
