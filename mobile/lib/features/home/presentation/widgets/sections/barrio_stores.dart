import 'package:apamuy/features/favorites/favorites.dart';
import 'package:apamuy/features/home/presentation/widgets/open_store.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Cerca de ti": negocios por cercanía con filtros rápidos. Los cerrados dicen
/// cuándo abren y ofrecen programar.
class BarrioStores extends ConsumerStatefulWidget {
  const BarrioStores({super.key});

  @override
  ConsumerState<BarrioStores> createState() => _BarrioStoresState();
}

class _BarrioStoresState extends ConsumerState<BarrioStores> {
  final _filters = <StoreFilter>{};

  void _toggle(StoreFilter f) => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f));

  @override
  Widget build(BuildContext context) {
    // Los filtros los aplica el backend; el conteo de abiertos es del barrio.
    final provider = storesProvider(filters: StoreFilters({..._filters}));
    final stores = ref.watch(provider);
    final shown = stores.value?.items ?? const <StoreSummary>[];
    final open = stores.value?.openCount ?? 0;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                'Cerca de ti',
                subtitle: stores.hasValue ? '$open ${open == 1 ? 'negocio abierto' : 'negocios abiertos'} ahora' : null,
              ),
              SizedBox(
                height: AppSpacing.minTouch,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.screen,
                  itemCount: StoreFilter.quick.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = StoreFilter.quick[index];
                    return AppChip(label: f.label, selected: _filters.contains(f), onTap: () => _toggle(f));
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        switch (stores) {
          AsyncValue(hasValue: true) when shown.isEmpty => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.gutter),
              child: AppEmptyState(title: 'Nada con esos filtros', message: 'Prueba quitando alguno.', compact: true),
            ),
          ),
          AsyncValue(hasValue: true) => SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, index) => FadeSlideIn.staggered(
              index: index,
              enabled: entranceWindowOpen(stores.value!),
              child: _BarrioStoreCard(store: shown[index]),
            ),
          ),
          AsyncError(:final error) => SliverToBoxAdapter(
            child: AppEmptyState.fromError(error, compact: true, onRetry: () => ref.invalidate(provider)),
          ),
          _ => SliverList.builder(
            itemCount: 2,
            itemBuilder: (_, _) => const AppStoreCardSkeleton(variant: AppStoreCardVariant.editorial),
          ),
        },
      ],
    );
  }
}

class _BarrioStoreCard extends ConsumerWidget {
  const _BarrioStoreCard({required this.store});

  final StoreSummary store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = storeCoverHeroTag(store.id, 'barrio');
    void open() => openStore(context, store.id, coverUrl: store.coverUrl, heroTag: tag);
    return AppStoreCard(
      variant: AppStoreCardVariant.editorial,
      heroTag: tag,
      isFavorite: ref.watch(isFavoriteStoreProvider(store.id)),
      onFavoriteToggle: () => toggleFavorite(context, ref, FavoriteKind.store, store.id),
      data: store.toCardData(withDistance: true, closedLabel: store.opensLabel(DateTime.now())),
      onSchedule: store.isOpenNow ? null : open,
      onTap: open,
    );
  }
}
