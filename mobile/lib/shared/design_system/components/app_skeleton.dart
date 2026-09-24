import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Envuelve un árbol de [SkeletonBox] con un shimmer gris muy suave (sin brillo).
/// Regla: el skeleton reproduce la geometría exacta de la pantalla real, así
/// el crossfade a los datos no produce saltos.
class Skeleton extends StatelessWidget {
  const Skeleton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.chaski;
    // Con movimiento reducido, bloques quietos (sin barrido).
    if (reduceMotionOf(context)) {
      return Semantics(label: 'Cargando', child: child);
    }
    return Semantics(
      label: 'Cargando',
      child: Shimmer.fromColors(
        baseColor: colors.shimmerBase,
        highlightColor: colors.shimmerHighlight,
        period: const Duration(milliseconds: 1400),
        child: child,
      ),
    );
  }
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

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
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
