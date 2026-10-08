import 'package:apamuy/shared/design_system/components/app_loader.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Espera de pantalla completa: el repartidor en moto, en bucle.
/// Para botones y campos está [AppLoader]. Con movimiento reducido queda quieto.
class AppWaitLoader extends StatelessWidget {
  const AppWaitLoader({this.size = 140, this.message, super.key});

  static const asset = 'assets/animations/moto.json';

  /// El Lottie trae mucho margen alrededor de la moto.
  static const zoom = 1.35;

  /// Punto fijo del zoom: corrido a la derecha para que no se corte la rueda delantera.
  static const zoomAlignment = Alignment(0.35, 0.1);

  final double size;

  /// Texto bajo la moto ("Buscando repartidor…").
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // En oscuro el casco y las ruedas (tinta) se perderían: va sobre un disco crema.
    final dark = theme.brightness == Brightness.dark;
    final moto = Lottie.asset(
      asset,
      animate: !reduceMotionOf(context),
      errorBuilder: (_, _, _) => const Center(child: AppLoader()),
    );
    return Semantics(
      label: message ?? 'Cargando',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: dark ? AppColors.papel : null, shape: BoxShape.circle),
            child: Transform.scale(scale: zoom, alignment: zoomAlignment, child: moto),
          ),
          if (message case final message?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
