import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// El recorrido mientras carga: cabecera, paradas y boleta en su lugar.
class DeliverySkeleton extends StatelessWidget {
  const DeliverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const PartnerPageHeader.skeleton(),
          Expanded(
            child: PartnerContent(
              maxWidth: 720,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
                children: [
                  Skeleton(
                    child: PartnerStations(
                      stations: [
                        const PartnerStation(
                          node: SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.button),
                          child: _Stop(title: 200),
                        ),
                        PartnerStation(
                          node: const SkeletonBox.circle(size: 44),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.tileExit),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Stop(title: 140, second: 170),
                                SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(child: SkeletonBox(height: 48, borderRadius: AppRadius.button)),
                                    SizedBox(width: AppSpacing.xs),
                                    Expanded(child: SkeletonBox(height: 48, borderRadius: AppRadius.button)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const PartnerStation(node: SkeletonBox.circle(size: 40), child: _Stop(title: 150, second: 120)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const TicketEdge(top: true),
                  const TicketSection(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, 10),
                    child: Skeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 110, height: 10),
                          SizedBox(height: 10),
                          SkeletonBox(width: 150),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 120),
                        ],
                      ),
                    ),
                  ),
                  const TicketEdge(top: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.title, this.second});

  final double title;
  final double? second;

  @override
  Widget build(BuildContext context) {
    final second = this.second;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 110, height: 10),
          const SizedBox(height: 6),
          SkeletonBox(width: title, height: 16),
          if (second != null) ...[const SizedBox(height: 6), SkeletonBox(width: second, height: 12)],
        ],
      ),
    );
  }
}
