import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/shared/design_system/components/app_badge.dart';
import 'package:apamuy/shared/design_system/components/app_button.dart';
import 'package:apamuy/shared/design_system/components/app_network_image.dart';
import 'package:apamuy/shared/design_system/components/store_card/favorite_button.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_data.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_parts.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Variante editorial de `AppStoreCard`: fotografía amplia y datos fuera de la
/// imagen. Interna del design system (se usa a través de `AppStoreCard`).
class StoreCardEditorial extends StatelessWidget {
  const StoreCardEditorial({required this.data, required this.isFavorite, this.heroTag, this.onFavoriteToggle, this.onSchedule, super.key});

  final StoreCardData data;
  final bool isFavorite;
  final Object? heroTag;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = [
      if (data.distanceKm != null) Formatters.distance(data.distanceKm!),
      if (data.minOrder != null && !data.minOrder!.isZero) 'mínimo ${Formatters.money(data.minOrder!)}' else 'sin mínimo',
    ].join(' · ');
    Widget cover = ExcludeSemantics(
      child: AppNetworkImage(url: data.coverUrl, borderRadius: AppRadius.card),
    );
    if (heroTag != null) cover = Hero(tag: heroTag!, child: cover);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: (constraints.maxWidth * 0.52).clamp(150, 240),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cover,
                  if (!data.isOpen) DecoratedBox(decoration: BoxDecoration(color: AppColors.inkOverlay(0.25), borderRadius: AppRadius.card)),
                  if (data.logoUrl != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: ExcludeSemantics(
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.surface, width: 3)),
                          child: AppNetworkImage(url: data.logoUrl, width: 40, height: 40, borderRadius: const BorderRadius.all(Radius.circular(20))),
                        ),
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavoriteToggle!, onPhoto: true),
                    ),
                  if (data.isOpen && data.promo != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ExcludeSemantics(
                        child: Align(alignment: Alignment.bottomLeft, child: AppCinta(data.promo!)),
                      ),
                    ),
                  if (!data.isOpen)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: StoreClosedBadge(closedLabel: data.closedLabel),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(data.name, style: theme.textTheme.titleLarge)),
                    if (data.rating != null) ...[
                      const SizedBox(width: 8),
                      AppRatingPill(data.rating!),
                    ],
                  ],
                ),
                if (data.subtitle != null) Text(data.subtitle!, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                // Principal: tiempo y envío. Secundario: distancia y mínimo.
                StoreEtaLine(data: data),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 2),
                  child: Text(secondary, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          if (!data.isOpen && onSchedule != null) ...[
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Programar pedido',
              icon: Icons.event_rounded,
              size: AppButtonSize.md,
              onPressed: onSchedule,
            ),
          ],
        ],
      ),
    );
  }
}
