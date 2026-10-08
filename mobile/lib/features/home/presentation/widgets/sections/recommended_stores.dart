import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/home/presentation/widgets/open_store.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Recomendados para ti": tiempo y envío arriba, distancia y mínimo debajo.
class RecommendedStores extends ConsumerWidget {
  const RecommendedStores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider(sort: StoreSort.popular, filters: const StoreFilters({StoreFilter.openNow}), limit: 3)).value?.items;
    if (stores == null || stores.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('Recomendados para ti'),
        for (final (i, store) in stores.indexed) ...[
          if (i > 0) const Padding(padding: AppSpacing.screen, child: Divider()),
          _RecommendedRow(store: store),
        ],
      ],
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  const _RecommendedRow({required this.store});

  final StoreSummary store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apamuy = context.apamuy;
    return AppTapSurface(
      semanticLabel: store.name,
      borderRadius: BorderRadius.zero,
      pressScale: 1,
      onTap: () => openStore(context, store.id, coverUrl: store.coverUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 10),
        child: Row(
          children: [
            AppNetworkImage(
              url: store.coverUrl,
              width: 84,
              height: 84,
              borderRadius: AppRadius.exit(20, cut: 6),
              fallbackIcon: Icons.storefront_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                  Text(
                    store.rating.hasReviews
                        ? '★ ${Formatters.rating(store.rating.average)} · ${store.rating.count} opiniones'
                        : 'Nuevo en $brandName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${Formatters.eta(store.etaMinutes)} · '),
                        if (store.deliveryFee.isZero)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: apamuy.accent, borderRadius: AppRadius.button),
                              child: Text('Envío gratis', style: theme.textTheme.labelMedium?.copyWith(color: apamuy.onAccent)),
                            ),
                          )
                        else
                          TextSpan(text: '${Formatters.money(store.deliveryFee)} envío'),
                      ],
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    '${Formatters.distance(store.distanceKm)} · ${store.toCardData().minOrderLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
