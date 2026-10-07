import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

/// Barrido gris muy suave de la marca; quieto si el usuario reduce el movimiento.
sk.PaintingEffect appSkeletonEffect(BuildContext context) {
  final colors = context.chaski;
  if (reduceMotionOf(context)) return sk.SolidColorEffect(color: colors.shimmerBase);
  return sk.ShimmerEffect(
    baseColor: colors.shimmerBase,
    highlightColor: colors.shimmerHighlight,
    duration: AppMotion.pulse,
  );
}

/// Convierte la pantalla real en skeleton: textos, imágenes e íconos se pintan
/// como bloques. Se le pasa el widget de verdad con datos de relleno, así la
/// geometría coincide sola y no hay que mantener un skeleton aparte.
class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final skeleton = sk.Skeletonizer(
      enabled: enabled,
      // Las tarjetas conservan su color; solo brilla el contenido.
      effect: appSkeletonEffect(context),
      child: child,
    );
    return enabled ? Semantics(label: 'Cargando', excludeSemantics: true, child: skeleton) : skeleton;
  }
}

/// Envuelve un árbol de [SkeletonBox] con el barrido de la marca. Solo se
/// sombrean los bloques; el resto (tarjetas, separadores) queda igual.
/// Regla: el skeleton reproduce la geometría exacta de la pantalla real, así
/// el crossfade a los datos no produce saltos.
class Skeleton extends StatelessWidget {
  const Skeleton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    child: sk.Skeletonizer.zone(effect: appSkeletonEffect(context), child: child),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(AppRadius.sm),
    super.key,
  });

  const SkeletonBox.circle({required double size, super.key})
    : width = size,
      height = size,
      borderRadius = const BorderRadius.all(AppRadius.pill);

  /// Bloque con radio de card (fotos, logos, categorías).
  const SkeletonBox.signature({this.width, this.height = 120, super.key}) : borderRadius = AppRadius.card;

  /// Ocupa todo el espacio disponible (placeholders de imagen).
  const SkeletonBox.expand({this.borderRadius = BorderRadius.zero, super.key}) : width = double.infinity, height = double.infinity;

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    // Dentro de un [Skeleton] lo pinta el barrido; suelto, un bloque quieto.
    if (sk.Skeletonizer.maybeOf(context)?.enabled ?? false) {
      // Sin ancho fijo ocupa lo disponible, como un Container vacío.
      return LimitedBox(
        maxWidth: 0,
        maxHeight: 0,
        child: sk.Bone(width: width ?? double.infinity, height: height, borderRadius: borderRadius),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: context.chaski.shimmerBase, borderRadius: borderRadius),
    );
  }
}

/// Líneas de texto de ancho decreciente (párrafos).
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({this.lines = 2, this.height = 12, this.gap = 6, super.key});

  final int lines;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) SizedBox(height: gap),
          FractionallySizedBox(widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1, child: SkeletonBox(height: height)),
        ],
      ],
    );
  }
}
