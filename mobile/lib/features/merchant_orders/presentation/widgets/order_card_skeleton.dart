import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Tarjeta de pedido en blanco mientras cargan: el mismo papel, con bloques
/// donde irán el número, los productos y las acciones.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({this.withActions = true, super.key});

  final bool withActions;

  @override
  Widget build(BuildContext context) {
    Widget line(double label) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const SkeletonBox(width: 20),
          const SizedBox(width: 8),
          Flexible(child: SkeletonBox(width: label)),
          const Spacer(),
          const SkeletonBox(width: 56),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: AppColors.inkOverlay(0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TicketEdge(top: true),
          const TicketSection(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 4),
            child: Skeleton(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 96, height: 10),
                        SizedBox(height: 8),
                        SkeletonBox(width: 110, height: 28),
                        SizedBox(height: 8),
                        SkeletonBox(width: 170, height: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SkeletonBox.circle(size: 64),
                ],
              ),
            ),
          ),
          const TicketPerforation(),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 8),
            child: Skeleton(
              child: Column(
                children: [
                  line(150),
                  line(120),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(children: [SkeletonBox(width: 140, height: 12), Spacer(), SkeletonBox(width: 90, height: 20)]),
                  ),
                ],
              ),
            ),
          ),
          if (withActions) ...[
            const TicketPerforation(),
            TicketSection(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 2, AppSpacing.md, 14),
              child: Skeleton(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 110, height: 12),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          const Flexible(child: SkeletonBox(width: 64, height: 36, borderRadius: AppRadius.button)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 52, borderRadius: AppRadius.button)),
                        SizedBox(width: 8),
                        Expanded(flex: 2, child: SkeletonBox(height: 52, borderRadius: AppRadius.button)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const TicketEdge(top: false),
        ],
      ),
    );
  }
}
