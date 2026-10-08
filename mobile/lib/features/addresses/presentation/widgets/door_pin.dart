import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Cuadro terracota con la esquina de salida de la app: la esquina corta
/// (abajo a la izquierda) es la que marca la puerta.
class DoorPin extends StatelessWidget {
  const DoorPin({super.key});

  static const size = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        boxShadow: AppShadows.raised(theme.brightness),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(3),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.home_rounded, size: 22, color: scheme.onPrimary),
    );
  }
}

/// [DoorPin] con su sombra en el suelo; se levanta mientras [lifted].
/// Centrado en un `Center`, la esquina queda justo en el centro.
class LiftingDoorPin extends StatelessWidget {
  const LiftingDoorPin({required this.lifted, super.key});

  final bool lifted;

  static const _shadowWidth = 14.0;

  @override
  Widget build(BuildContext context) {
    final motion = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    const pin = DoorPin.size;
    // La caja mide pin × 2 pin; la esquina del pin cae en su centro.
    return SizedBox(
      width: pin * 2,
      height: pin * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: pin - (lifted ? _shadowWidth / 4 : _shadowWidth / 2),
            top: pin - 2.5,
            child: AnimatedContainer(
              duration: motion,
              width: lifted ? _shadowWidth / 2 : _shadowWidth,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.all(AppRadius.pill),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: motion,
            left: pin,
            top: lifted ? -14 : 0,
            child: const DoorPin(),
          ),
        ],
      ),
    );
  }
}
