import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Carga del seguimiento: mapa gris y la hoja con bloques que brillan.
class TrackingSkeleton extends StatelessWidget {
  const TrackingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu pedido')),
      body: Semantics(
        label: 'Buscando tu pedido',
        child: Skeleton(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            children: [
              SkeletonBox(height: height * 0.3, borderRadius: AppRadius.card),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(width: 80),
              const SizedBox(height: AppSpacing.xs),
              const SkeletonBox(width: 160, height: 32),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonLines(lines: 4),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(height: 64, borderRadius: AppRadius.card),
            ],
          ),
        ),
      ),
    );
  }
}
