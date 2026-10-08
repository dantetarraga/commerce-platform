import 'dart:math' as math;

import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Gota de la marca con la "a" al centro; la punta marca la puerta.
class DoorPin extends StatelessWidget {
  const DoorPin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: scheme.primary,
          boxShadow: AppShadows.raised(theme.brightness),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(23),
            topRight: Radius.circular(23),
            bottomRight: Radius.circular(23),
            bottomLeft: Radius.circular(4),
          ),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: BrandMark(size: 24, color: scheme.onPrimary, dot: scheme.onPrimary),
        ),
      ),
    );
  }
}

/// [DoorPin] con su sombra en el suelo; se levanta mientras [lifted].
class LiftingDoorPin extends StatelessWidget {
  const LiftingDoorPin({required this.lifted, super.key});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final motion = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    return Transform.translate(
      offset: const Offset(0, -26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: motion,
            transform: Matrix4.translationValues(0, lifted ? -14 : 0, 0),
            child: const DoorPin(),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: motion,
            width: lifted ? 8 : 14,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.all(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}
