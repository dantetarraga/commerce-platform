import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/app_badge.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/components/store_card/favorite_button.dart';
import 'package:chaski/shared/design_system/components/store_card/store_card_data.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Variante destacada de `AppStoreCard`: foto grande con logo, oferta y
/// favorito encima. Interna del design system.
class StoreCardFeature extends StatelessWidget {
  const StoreCardFeature({
    required this.data,
    required this.width,
    required this.isFavorite,
    this.heroTag,
    this.onFavoriteToggle,
    super.key,
  });

  final StoreCardData data;
  final double width;
  final Object? heroTag;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cover = ExcludeSemantics(
      child: AppNetworkImage(url: data.coverUrl, width: width),
    );
    if (heroTag != null) cover = Hero(tag: heroTag!, child: cover);
    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (context, constraints) => ClipRRect(
          borderRadius: AppRadius.card,
          child: SizedBox(
            height: constraints.hasBoundedHeight ? constraints.maxHeight : (width * 0.8).clamp(180.0, 320.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                cover,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.2, 0.65, 1],
                      colors: [AppColors.inkOverlay(0), AppColors.inkOverlay(0.69), AppColors.inkOverlay(0.94)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  right: 56,
                  child: ExcludeSemantics(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: data.promo != null
                          ? AppCinta(data.promo!)
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                              child: Text(
                                data.isOpen ? Formatters.eta(data.etaMinutes) : data.closedLabel ?? 'Cerrado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.terracota700),
                              ),
                            ),
                    ),
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavoriteToggle!, onPhoto: true),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.blanco, size: 15),
                              const SizedBox(width: 4),
                              Text(data.rating!.toStringAsFixed(1), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.blanco)),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Text(
                          data.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.blanco, fontSize: width > 300 ? 25 : 20, height: 1.1),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          data.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: context.chaski.onPhotoMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
