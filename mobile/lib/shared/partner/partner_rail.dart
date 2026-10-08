import 'dart:math' as math;

import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Riel de cocina con su título: las comandas cuelgan debajo.
class PartnerRail extends StatelessWidget {
  const PartnerRail({required this.title, required this.dot, required this.children, this.count, this.empty, super.key});

  final String title;

  /// Sin número mientras carga.
  final int? count;
  final Color dot;
  final List<Widget> children;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            if (count case final n?)
              Text('$n', style: AppTypography.price(context))
            else
              const Skeleton(child: SkeletonBox(width: 18, height: 20)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5A4A42), AppColors.tinta],
            ),
            boxShadow: AppShadows.knob,
          ),
        ),
        const SizedBox(height: 20),
        if (children.isEmpty && empty != null) empty!,
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 26),
          Transform.rotate(
            angle: (i.isEven ? -0.8 : 0.6) * math.pi / 180,
            child: _Clipped(child: c),
          ),
        ],
      ],
    );
  }
}

class _Clipped extends StatelessWidget {
  const _Clipped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned(
        top: -22,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: 36,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.tinta,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
