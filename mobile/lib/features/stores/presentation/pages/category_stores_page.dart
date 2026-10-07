import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/stores/domain/entities/store_filter.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/presentation/pages/store_detail_page.dart';
import 'package:chaski/features/stores/presentation/providers/stores_providers.dart';
import 'package:chaski/features/stores/presentation/widgets/category_visuals.dart';
import 'package:chaski/features/stores/presentation/widgets/store_mappers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Negocios de una categoría. Los filtros, el conteo y "Ordenar" se quedan
/// pegados arriba al bajar.
class CategoryStoresPage extends ConsumerStatefulWidget {
  const CategoryStoresPage({required this.categoryId, super.key});

  static const name = 'category-stores';

  final String categoryId;

  @override
  ConsumerState<CategoryStoresPage> createState() => _CategoryStoresPageState();
}

class _CategoryStoresPageState extends ConsumerState<CategoryStoresPage> {
  final _filters = <StoreFilter>{};
  StoreSort _sort = StoreSort.distance;

  void _toggle(StoreFilter f) => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f));

  Future<void> _chooseSort() async {
    final picked = await showAppBottomSheet<StoreSort>(
      context,
      title: 'Ordenar por',
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final sort in StoreSort.values)
                Semantics(
                  selected: sort == _sort,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    minTileHeight: AppSpacing.minTouch + 8,
                    title: Text(sort.label, style: theme.textTheme.titleSmall),
                    trailing: sort == _sort ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
                    onTap: () => Navigator.of(context).pop(sort),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(categoriesProvider).value?.where((c) => c.id == widget.categoryId).firstOrNull;
    final provider = storesProvider(sort: _sort, categoryId: widget.categoryId);
    final stores = ref.watch(provider);
    final items = stores.value?.items.matching(_filters).openFirst();
    final title = category == null ? 'Negocios' : categoryShelfLabel(category.slug, category.name);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedFilters(
                  title: title,
                  count: items?.length,
                  filters: _filters,
                  sort: _sort,
                  onToggle: _toggle,
                  onSort: _chooseSort,
                ),
              ),
              switch (stores) {
                AsyncValue(hasValue: true) when items!.isEmpty => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    kind: AppEmptyKind.noResults,
                    title: _filters.isNotEmpty ? 'Nada con esos filtros' : 'Aún no hay negocios aquí',
                    message: _filters.isNotEmpty
                        ? 'Prueba quitando un filtro.'
                        : 'Pronto se sumarán negocios de esta categoría en tu zona.',
                    actionLabel: _filters.isNotEmpty ? 'Quitar filtros' : null,
                    onAction: _filters.isNotEmpty ? () => setState(_filters.clear) : null,
                    compact: true,
                  ),
                ),
                AsyncValue(hasValue: true) => SliverList.builder(
                  itemCount: items!.length,
                  itemBuilder: (context, index) => FadeSlideIn.staggered(
                    index: index,
                    enabled: entranceWindowOpen(stores.value!),
                    child: _StoreRow(store: items[index]),
                  ),
                ),
                AsyncError(:final error) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState.fromError(error, onRetry: () => ref.invalidate(provider)),
                ),
                _ => SliverList.builder(
                  itemCount: 6,
                  itemBuilder: (_, _) => const AppStoreCardSkeleton(variant: AppStoreCardVariant.row),
                ),
              },
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de negocio; si está cerrado se atenúa y dice cuándo abre.
class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store});

  final StoreSummary store;

  @override
  Widget build(BuildContext context) {
    final card = AppStoreCard(
      variant: AppStoreCardVariant.row,
      data: store.toCardData(withDistance: true, closedLabel: store.isOpenNow ? null : store.closedLabel(DateTime.now())),
      onTap: () => context.pushNamed(
        StoreDetailPage.name,
        pathParameters: {'storeId': store.id},
        extra: StoreRouteArgs(coverUrl: store.coverUrl),
      ),
    );
    return store.isOpenNow ? card : Opacity(opacity: 0.75, child: card);
  }
}

/// Cabecera fija: título + buscar, chips de filtro y "N negocios · Ordenar".
class _PinnedFilters extends SliverPersistentHeaderDelegate {
  const _PinnedFilters({
    required this.title,
    required this.count,
    required this.filters,
    required this.sort,
    required this.onToggle,
    required this.onSort,
  });

  static const _barHeight = 56.0;
  static const _chipsHeight = 60.0;
  static const _sortHeight = 48.0;

  final String title;
  final int? count;
  final Set<StoreFilter> filters;
  final StoreSort sort;
  final ValueChanged<StoreFilter> onToggle;
  final VoidCallback onSort;

  @override
  double get minExtent => _barHeight + _chipsHeight + _sortHeight;

  @override
  double get maxExtent => minExtent;

  @override
  bool shouldRebuild(covariant _PinnedFilters old) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final raised = overlapsContent || shrinkOffset > 0;
    return AnimatedContainer(
      duration: AppMotion.quick,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: raised ? AppShadows.soft(theme.brightness) : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: _barHeight,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.xxs),
                const BackButton(),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => context.goNamed(ExplorePage.name),
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
            ),
          ),
          SizedBox(
            height: _chipsHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 6),
              itemCount: StoreFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final f = StoreFilter.values[index];
                return AppChip(
                  label: f.label,
                  selected: filters.contains(f),
                  onTap: () => onToggle(f),
                );
              },
            ),
          ),
          SizedBox(
            height: _sortHeight,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.gutter, right: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: count == null
                        ? const SizedBox.shrink()
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: count == 1 ? '1 negocio' : '$count negocios',
                                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(text: ' cerca'),
                              ],
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                  ),
                  TextButton(
                    onPressed: onSort,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ordenar: ${sort.inlineLabel}', style: theme.textTheme.labelLarge),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
