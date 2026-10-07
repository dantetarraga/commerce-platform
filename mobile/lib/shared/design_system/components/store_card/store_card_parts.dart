import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/store_card/store_card_data.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Píldora de calificación: estrella y nota con un decimal sobre el
/// contenedor primario ("★ 4.8").
class AppRatingPill extends StatelessWidget {
  const AppRatingPill(this.rating, {super.key});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.button),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 15, color: context.chaski.rating),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

/// Ficha "Cerrado por ahora" con la próxima apertura. Va sobre la foto: sus
/// colores no cambian con el tema.
class StoreClosedBadge extends StatelessWidget {
  const StoreClosedBadge({this.closedLabel, super.key});

  final String? closedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round, size: 18, color: AppColors.terracota700),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cerrado por ahora', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.tinta)),
                if (closedLabel != null)
                  Text(
                    closedLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.piedra),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "20–30 min · S/ 3.00 envío" con el ícono de moto; el envío gratis
/// va en verde.
class StoreEtaLine extends StatelessWidget {
  const StoreEtaLine({required this.data, super.key});

  final StoreCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fee = data.deliveryFee.isZero ? null : '${Formatters.money(data.deliveryFee)} envío';
    return Row(
      children: [
        Icon(Icons.moped_rounded, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${Formatters.eta(data.etaMinutes)} · '),
                if (fee != null) TextSpan(text: fee) else TextSpan(text: 'Envío gratis', style: TextStyle(color: context.chaski.success)),
              ],
            ),
            style: theme.textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

/// "★ 4.8 · 20–30 min · Envío gratis": una sola línea, el envío gratis en verde.
class StoreMetaLine extends StatelessWidget {
  const StoreMetaLine({required this.data, super.key});

  final StoreCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    final muted = theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600);
    final free = data.deliveryFee.isZero;
    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), shape: BoxShape.circle),
      ),
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          if (data.rating != null) ...[
            Icon(Icons.star_rounded, size: 15, color: chaski.rating),
            const SizedBox(width: 2),
            Text(data.rating!.toStringAsFixed(1), style: muted.copyWith(color: theme.colorScheme.onSurface)),
            dot(),
          ],
          Flexible(
            child: Text(Formatters.eta(data.etaMinutes), style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          dot(),
          Flexible(
            child: Text(
              free ? 'Envío gratis' : 'Envío ${Formatters.money(data.deliveryFee)}',
              style: free ? muted.copyWith(color: chaski.success) : muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
