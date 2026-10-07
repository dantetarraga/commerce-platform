import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Tres bloques: calificación, tiempo y envío (con el pedido mínimo).
class StoreStatBlocks extends StatelessWidget {
  const StoreStatBlocks({required this.summary, super.key});

  final StoreSummary summary;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.price(context, size: 17);
    final rating = summary.rating;
    final eta = summary.etaMinutes;
    final fee = summary.deliveryFee;
    final min = summary.minOrderAmount;
    return Row(
      children: [
        _StatBlock(
          value: rating.hasReviews
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 17, color: context.chaski.rating),
                    const SizedBox(width: 2),
                    Text(Formatters.rating(rating.average), style: valueStyle),
                  ],
                )
              : Text('Nuevo', style: valueStyle),
          label: rating.hasReviews ? '${rating.count} opiniones' : 'sin opiniones',
          semantics: rating.hasReviews
              ? '${Formatters.rating(rating.average)} estrellas, ${rating.count} opiniones'
              : 'Negocio nuevo, sin opiniones aún',
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatBlock(
          value: Text('${eta - 5}–${eta + 5}', style: valueStyle),
          label: 'minutos',
          semantics: 'Llega en ${eta - 5} a ${eta + 5} minutos',
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatBlock(
          value: Text(fee.isZero ? 'Gratis' : Formatters.money(fee), style: valueStyle),
          // En un tercio de pantalla no entra "envío · mín. S/ 12.00" en una línea.
          label: min.isZero ? 'envío' : 'envío\nmín. ${Formatters.shortMoney(min)}',
          semantics: [
            if (fee.isZero) 'Envío gratis' else 'Envío ${spokenMoney(fee)}',
            if (!min.isZero) 'pedido mínimo ${spokenMoney(min)}',
          ].join(', '),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label, required this.semantics});

  final Widget value;
  final String label;
  final String semantics;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        // Misma altura para los tres aunque el de envío use dos líneas.
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            value,
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

class StoreStatBlocksSkeleton extends StatelessWidget {
  const StoreStatBlocksSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
            child: const Skeleton(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [SkeletonBox(width: 56, height: 18), SizedBox(height: 6), SkeletonBox(width: 64, height: 10)],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
