import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Se muestra mientras se restaura la sesión. El router redirige al terminar.
///
/// El fondo cobalto coincide con el splash nativo, así que el paso del sistema
/// a Flutter no se nota. La marca entra con escala + fade y el cargador de hilo
/// solo aparece si la restauración tarda.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const name = 'splash';

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotionOf(context);
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0, end: 1),
              duration: reduced ? Duration.zero : const Duration(milliseconds: 700),
              curve: AppMotion.knot,
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
              ),
              // Arte de marca: no escala con el tamaño de texto del sistema.
              child: MediaQuery.withNoTextScaling(
                child: Semantics(
                  label: 'Chaski. Lo de tu barrio, en minutos',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ChaskiMark(size: 76, inverted: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'chaski',
                        style: TextStyle(
                          fontFamily: AppTypography.display,
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Lo de tu barrio, en minutos',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: const Duration(milliseconds: 600),
              offset: Offset.zero,
              child: ThreadLoader(color: onPrimary, semanticLabel: 'Preparando Chaski'),
            ),
          ],
        ),
      ),
    );
  }
}
