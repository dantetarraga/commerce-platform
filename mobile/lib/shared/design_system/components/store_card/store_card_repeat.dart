import 'package:apamuy/shared/design_system/components/app_network_image.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_data.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Variante "Volver a pedir" de `AppStoreCard`: solo logo y nombre. Interna
/// del design system.
class StoreCardRepeat extends StatelessWidget {
  const StoreCardRepeat({required this.data, super.key});

  final StoreCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppNetworkImage(url: data.logoUrl, width: 64, height: 64, borderRadius: AppRadius.tile),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(Icons.replay_rounded, size: 13, color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
