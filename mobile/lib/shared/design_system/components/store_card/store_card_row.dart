import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/shared/design_system/components/app_badge.dart';
import 'package:apamuy/shared/design_system/components/app_network_image.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_data.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_parts.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Variante fila de `AppStoreCard`: foto compacta y datos al lado ("De tu
/// barrio"). Interna del design system.
class StoreCardRow extends StatelessWidget {
  const StoreCardRow({required this.data, this.heroTag, super.key});

  final StoreCardData data;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget photo = Opacity(
      opacity: data.isOpen ? 1 : 0.55,
      child: AppNetworkImage(
        url: data.coverUrl ?? data.logoUrl,
        width: 94,
        height: 104,
        borderRadius: AppRadius.card,
      ),
    );
    if (heroTag != null) photo = Hero(tag: heroTag!, child: photo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      child: Row(
        children: [
          photo,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                if (data.isOpen) StoreMetaLine(data: data) else AppBadge(AppBadgeStatus.closed, label: data.closedLabel ?? 'Cerrado ahora'),
                if (data.minOrder != null || data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle ?? data.minOrderLabel,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (data.promo != null) ...[const SizedBox(height: AppSpacing.xxs), AppCinta(data.promo!, dense: true)],
              ],
            ),
          ),
          if (data.distanceKm != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              Formatters.distance(data.distanceKm!),
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
