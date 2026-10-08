import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Tres fotos a sangre, una por estación (Descubre, Elige, Recibe), que se deslizan
/// con el dedo. La foto se mueve un poco menos que su marco: da profundidad sin dibujos.
class CityOnboardingScene extends StatelessWidget {
  const CityOnboardingScene({required this.page, required this.still, super.key});

  final double page;
  final bool still;

  /// Fotos de demostración hasta tener fotos reales de Yauri.
  static const List<(String, String, IconData)> _stations = [
    ('assets/images/demo/table.jpg', 'DESCUBRE', Icons.storefront_rounded),
    ('assets/images/demo/burger.jpg', 'ELIGE', Icons.shopping_bag_outlined),
    ('assets/images/demo/pizza.jpg', 'RECIBE', Icons.door_front_door_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final p = still ? page.roundToDouble() : page;
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: ColoredBox(
          color: AppColors.tinta,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                fit: StackFit.expand,
                children: [
                  for (final (i, (photo, label, icon)) in _stations.indexed)
                    if ((i - p).abs() < 1.2)
                      Positioned(
                        left: (i - p) * w,
                        width: w,
                        top: 0,
                        bottom: 0,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              photo,
                              fit: BoxFit.cover,
                              alignment: Alignment(((p - i) * 0.8).clamp(-1.0, 1.0), 0),
                            ),
                            // Oscurece abajo para que la etiqueta se lea sobre cualquier foto.
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0, 0.35, 1],
                                  colors: [AppColors.inkOverlay(0.33), AppColors.inkOverlay(0), AppColors.inkOverlay(0.7)],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              bottom: 18,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                                decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 18, color: AppColors.terracota),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.tinta,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  Positioned(
                    left: 20,
                    top: 18,
                    child: Text('DE AQUÍ. PARA TI.', style: AppTypography.eyebrow(context).copyWith(color: AppColors.blanco)),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 24,
                    child: Text(
                      '0${page.round() + 1} / 03',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.blanco, fontWeight: FontWeight.w700),
                    ),
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
