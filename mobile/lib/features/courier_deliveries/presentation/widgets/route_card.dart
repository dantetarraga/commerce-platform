import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// Un recorrido para tomar: sale del negocio y llega a la casa por el trazo.
class RouteCard extends StatelessWidget {
  const RouteCard({required this.order, required this.first, required this.taking, required this.onTake, super.key});

  final StaffOrder order;

  /// El primero de la lista va resaltado.
  final bool first;
  final bool taking;
  final VoidCallback? onTake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = context.chaski.accent;
    final label = AppTypography.eyebrow(context).copyWith(letterSpacing: 1);
    final place = AppTypography.displayStyle(context, size: 18);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: first ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            PartnerStoreLogo(url: order.order.store.logoUrl, size: 40, borderWidth: 2, borderColor: scheme.primary),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: TrackLine(vertical: true),
                              ),
                            ),
                            StationNode(icon: Icons.home_rounded, color: accent, size: 28),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Deja sitio al sello de la ganancia.
                          Padding(
                            padding: const EdgeInsets.only(right: 84),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SALE DE · ${staffTimeAgo(order.order.placedAt).toUpperCase()}',
                                  style: label.copyWith(color: scheme.primary),
                                ),
                                Text(order.order.store.name, style: place),
                                Text(order.pickup.address, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('LLEGA A · ${Formatters.meters(order.distanceMeters)}', style: label.copyWith(color: accent)),
                          Text(order.order.addressStreet, style: place),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Semantics(
                  label: 'Ganas ${Formatters.money(order.order.deliveryFee)}',
                  excludeSemantics: true,
                  child: PartnerStamp('+${Formatters.money(order.order.deliveryFee)}', color: accent, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StaffCollectSummary.compact(order: order.order),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Tomar recorrido', icon: Icons.arrow_forward_rounded, loading: taking, onPressed: onTake),
        ],
      ),
    );
  }
}

/// Recorrido en blanco, con el mismo alto que [RouteCard].
class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.card),
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        const SkeletonBox.circle(size: 44),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: TrackLine(vertical: true, color: context.chaski.shimmerBase),
                          ),
                        ),
                        const SkeletonBox.circle(size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonBox(width: 110, height: 10),
                                  SizedBox(height: 6),
                                  SkeletonBox(width: 130, height: 18),
                                  SizedBox(height: 6),
                                  SkeletonBox(width: 120, height: 12),
                                ],
                              ),
                            ),
                            SizedBox(width: AppSpacing.xs),
                            SkeletonBox(width: 70, height: 28, borderRadius: AppRadius.tile),
                          ],
                        ),
                        Spacer(),
                        SkeletonBox(width: 90, height: 10),
                        SizedBox(height: 6),
                        SkeletonBox(width: 150, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(height: 46, borderRadius: AppRadius.tile),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(height: 52, borderRadius: AppRadius.button),
          ],
        ),
      ),
    );
  }
}
