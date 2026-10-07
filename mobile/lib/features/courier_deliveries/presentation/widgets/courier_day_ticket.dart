import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La jornada como boleta de rendición: lo cobrado por medio y el efectivo en mano.
class CourierDayTicket extends ConsumerWidget {
  const CourierDayTicket({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final strong = row?.copyWith(fontWeight: FontWeight.w800);
    return AsyncValueView(
      value: ref.watch(courierSummaryProvider),
      compactError: true,
      onRetry: () => ref.invalidate(courierSummaryProvider),
      loading: const _DayTicketSkeleton(),
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu jornada de hoy', style: theme.textTheme.headlineSmall),
          Text(
            '${summary.deliveredCount} ${summary.deliveredCount == 1 ? 'entrega completada' : 'entregas completadas'}',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('RENDICIÓN DEL DÍA', style: AppTypography.eyebrow(context))),
                    const PartnerStamp('PARA RENDIR', size: 11),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final (label, amount) in [('Yape', summary.yape), ('Plin', summary.plin), ('Efectivo', summary.cash)]) ...[
                  LeaderRow(label: Text(label, style: row), value: Text(Formatters.money(amount), style: row)),
                  const SizedBox(height: 6),
                ],
                LeaderRow(
                  label: Text('Total cobrado', style: strong),
                  value: Text(Formatters.money(summary.total), style: strong),
                ),
              ],
            ),
          ),
          const TicketPerforation(),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 10),
            child: LeaderRow(
              label: Text('Efectivo en mano', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              value: Text(Formatters.money(summary.cash), style: AppTypography.price(context, size: 26)),
            ),
          ),
          const TicketEdge(top: false),
        ],
      ),
    );
  }
}

class _DayTicketSkeleton extends StatelessWidget {
  const _DayTicketSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SkeletonBox(width: 190, height: 24), SizedBox(height: AppSpacing.xs), SkeletonBox(width: 150)],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const TicketEdge(top: true),
      TicketSection(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, 2),
        child: Skeleton(
          child: Column(
            children: [
              const Row(
                children: [
                  SkeletonBox(width: 120, height: 10),
                  Spacer(),
                  SkeletonBox(width: 86, height: 22, borderRadius: AppRadius.tile),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final width in [50.0, 40.0, 70.0, 100.0]) _SkeletonRow(label: width),
            ],
          ),
        ),
      ),
      const TicketPerforation(),
      const TicketSection(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        child: Skeleton(child: Row(children: [SkeletonBox(width: 120), Spacer(), SkeletonBox(width: 100, height: 26)])),
      ),
      const TicketEdge(top: false),
    ],
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.label});

  final double label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [SkeletonBox(width: label), const Spacer(), const SkeletonBox(width: 64)]),
  );
}
