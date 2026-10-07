import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/presentation/quick_add_product.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Resultados en pestañas: "Productos · N" y "Negocios · N".
class SearchResultsView extends ConsumerStatefulWidget {
  const SearchResultsView({required this.results, required this.onOpen, super.key});

  final SearchResults results;

  /// Se llama al abrir un resultado (guarda la búsqueda en recientes).
  final VoidCallback onOpen;

  @override
  ConsumerState<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<SearchResultsView> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: 2,
    vsync: this,
    // Si no hay productos, abre directo en Negocios.
    initialIndex: widget.results.products.isEmpty ? 1 : 0,
  );
  var _openOnly = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<bool> _quickAdd(ProductHit p, StoreSummary? known) {
    widget.onOpen();
    return quickAddProduct(context, ref, p, known: known);
  }

  void _openProduct(ProductHit p) {
    widget.onOpen();
    context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': p.id}).ignore();
  }

  void _openStore(StoreHit hit, StoreSummary? summary) {
    widget.onOpen();
    context
        .pushNamed(StoreDetailPage.name, pathParameters: {'storeId': hit.id}, extra: StoreRouteArgs(coverUrl: summary?.coverUrl))
        .ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final results = widget.results;
    // Los negocios cercanos ya cargados dan el tiempo de entrega y la bolsa.
    final nearby = {for (final s in ref.watch(storesProvider()).value?.items ?? const <StoreSummary>[]) s.id: s};
    final stores = [
      for (final s in results.stores)
        if (!_openOnly || s.isOpenNow) s,
    ];
    final animate = entranceWindowOpen(results);

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter - AppSpacing.sm),
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: theme.textTheme.titleSmall,
          unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          indicatorColor: scheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: scheme.outlineVariant,
          tabs: [
            Tab(text: 'Productos · ${results.products.length}'),
            Tab(text: 'Negocios · ${results.stores.length}'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              if (results.products.isEmpty)
                const AppEmptyState(
                  kind: AppEmptyKind.noResults,
                  title: 'Ningún producto con ese nombre',
                  message: 'Mira la pestaña Negocios.',
                  compact: true,
                )
              else
                ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxl),
                  itemCount: results.products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxs),
                  itemBuilder: (context, i) {
                    final p = results.products[i];
                    final store = nearby[p.storeId];
                    return FadeSlideIn.staggered(
                      index: i,
                      enabled: animate,
                      child: AppProductCard(
                        data: ProductCardData(
                          id: p.id,
                          name: p.name,
                          price: p.price,
                          imageUrl: p.imageUrl,
                          description: store == null ? p.storeName : '${p.storeName} · ${Formatters.eta(store.etaMinutes)}',
                          subtitle: p.storeName,
                          fromPrice: p.hasChoices,
                        ),
                        onQuickAdd: p.hasChoices ? null : () => _quickAdd(p, store),
                        onTap: () => _openProduct(p),
                      ),
                    );
                  },
                ),
              CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (results.stores.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxs),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            AppChip(label: 'Abierto ahora', selected: _openOnly, onTap: () => setState(() => _openOnly = !_openOnly)),
                          ],
                        ),
                      ),
                    ),
                  if (stores.isEmpty)
                    SliverToBoxAdapter(
                      child: AppEmptyState(
                        kind: AppEmptyKind.noResults,
                        title: _openOnly ? 'Ninguno abierto ahora' : 'Ningún negocio con ese nombre',
                        message: _openOnly ? 'Quita el filtro o programa tu pedido.' : 'Mira la pestaña Productos.',
                        compact: true,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    sliver: SliverList.builder(
                      itemCount: stores.length,
                      itemBuilder: (context, i) => FadeSlideIn.staggered(
                        index: i,
                        enabled: animate,
                        child: _StoreHitRow(
                          hit: stores[i],
                          summary: nearby[stores[i].id],
                          onTap: () => _openStore(stores[i], nearby[stores[i].id]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Con el negocio cercano ya cargado ([summary]), su card completa; si no, una
/// fila básica con logo, estado y tiempo.
class _StoreHitRow extends StatelessWidget {
  const _StoreHitRow({required this.hit, required this.summary, required this.onTap});

  final StoreHit hit;
  final StoreSummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (summary case final summary?) {
      return AppStoreCard(variant: AppStoreCardVariant.row, data: summary.toCardData(withDistance: true), onTap: onTap);
    }
    final theme = Theme.of(context);
    final eta = Formatters.eta(hit.etaMinutes);
    return AppTapSurface(
      semanticLabel: '${hit.name}. ${hit.isOpenNow ? 'Abierto' : 'Cerrado'}. $eta',
      borderRadius: BorderRadius.zero,
      pressScale: 1,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Opacity(
              opacity: hit.isOpenNow ? 1 : 0.55,
              child: AppNetworkImage(
                url: hit.logoUrl,
                width: 68,
                height: 68,
                borderRadius: const BorderRadius.all(AppRadius.lg),
                fallbackIcon: Icons.storefront_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AppBadge(hit.isOpenNow ? AppBadgeStatus.open : AppBadgeStatus.closed),
                      const SizedBox(width: AppSpacing.xs),
                      Text(eta, style: theme.textTheme.bodySmall),
                    ],
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
