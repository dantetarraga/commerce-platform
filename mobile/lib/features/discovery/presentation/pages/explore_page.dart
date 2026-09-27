import 'package:chaski/core/utils/debouncer.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:chaski/features/discovery/presentation/providers/popular_searches_providers.dart';
import 'package:chaski/features/discovery/presentation/providers/recent_searches.dart';
import 'package:chaski/features/discovery/presentation/providers/search_providers.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Explorar": sé lo que quiero. Abre con el buscador listo; los resultados
/// van en pestañas Productos · Negocios.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  static const name = 'explore';

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) => _debouncer.run(() => ref.read(searchQueryProvider.notifier).update(value));

  void _search(String value) {
    _controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    ref.read(searchQueryProvider.notifier).update(value);
    ref.read(recentSearchesProvider.notifier).add(value).ignore();
    _focus.unfocus();
  }

  void _remember() => ref.read(recentSearchesProvider.notifier).add(_controller.text).ignore();

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(currentMomentProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);
    final searching = query.length >= SearchCatalog.minQueryLength;
    // Con resultados previos en pantalla, una barra fina avisa que se actualizan.
    final refreshing = searching && results.isLoading && results.hasValue;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Sigue tu antojo.', style: Theme.of(context).textTheme.headlineLarge)),
                  const SizedBox(width: 54, height: 30, child: ChaskiTrail(strokeWidth: 3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xs),
              child: AppSearchBar(
                variant: AppSearchBarVariant.compact,
                hints: const ['Negocios, platos o productos'],
                controller: _controller,
                focusNode: _focus,
                autofocus: query.isEmpty,
                onChanged: _onChanged,
                onSubmitted: _search,
                onClear: () => _search(''),
              ),
            ),
            SizedBox(
              height: 2,
              child: AnimatedOpacity(
                opacity: refreshing ? 1 : 0,
                duration: AppMotion.quick,
                child: refreshing ? const LinearProgressIndicator(minHeight: 2) : null,
              ),
            ),
            Expanded(
              child: LoadCrossFade(
                stateKey: searching ? 'results' : 'idle',
                child: !searching
                    ? _Idle(onPick: _search, hints: moment.searchHints)
                    : AsyncValueView(
                        value: results,
                        onRetry: () => ref.invalidate(searchResultsProvider),
                        loading: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [for (var i = 0; i < 6; i++) const AppProductRowSkeleton()],
                        ),
                        isEmpty: (r) => r.isEmpty,
                        empty: _NoResults(query: query, onPick: _search),
                        data: (r) => _Results(key: ValueKey(query), results: r, onOpen: _remember),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _groupTitle(BuildContext context, String text, {Widget? action}) => Padding(
  padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, action == null ? AppSpacing.gutter : AppSpacing.xs, AppSpacing.xs),
  child: SizedBox(
    height: action == null ? null : AppSpacing.minTouch,
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(text, style: AppTypography.eyebrow(context))),
        ),
        ?action,
      ],
    ),
  ),
);

/// Estado inicial: RECIENTES (chips con reloj) y LO MÁS PEDIDO EN ESPINAR.
class _Idle extends ConsumerWidget {
  const _Idle({required this.onPick, required this.hints});

  final ValueChanged<String> onPick;

  /// Respaldo si aún no llega "lo más pedido" (ejemplos del momento).
  final List<String> hints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    final popular = ref.watch(popularSearchesProvider);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (recent.isNotEmpty) ...[
          _groupTitle(
            context,
            'RECIENTES',
            action: AppButton.ghost(label: 'Borrar', size: AppButtonSize.sm, onPressed: () => ref.read(recentSearchesProvider.notifier).clear()),
          ),
          Padding(
            padding: AppSpacing.screen,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final q in recent) AppChip(label: q, icon: Icons.schedule_rounded, variant: AppChipVariant.suggestion, onTap: () => onPick(q)),
              ],
            ),
          ),
        ],
        _groupTitle(context, 'LO MÁS PEDIDO EN ESPINAR'),
        switch (popular) {
          AsyncValue(:final value?) => Column(
            children: [
              for (final p in value)
                Semantics(
                  button: true,
                  label: '${p.term}, en ${_storesLabel(p.storeCount)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onPick(p.term),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs + 2),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
                            child: Icon(Icons.trending_up_rounded, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.term, style: theme.textTheme.titleSmall),
                                Text('en ${_storesLabel(p.storeCount)}', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          AsyncError() => Padding(
            padding: AppSpacing.screen,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final h in hints)
                  AppChip(
                    label: h.replaceFirst('Busca ', ''),
                    icon: Icons.trending_up_rounded,
                    variant: AppChipVariant.suggestion,
                    onTap: () => onPick(h.replaceFirst('Busca ', '')),
                  ),
              ],
            ),
          ),
          _ => Skeleton(
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs + 2),
                    child: Row(
                      children: [
                        SkeletonBox(width: 44, height: 44),
                        SizedBox(width: AppSpacing.sm),
                        SkeletonBox(width: 160),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        },
      ],
    );
  }
}

String _storesLabel(int count) => count == 1 ? '1 negocio' : '$count negocios';

/// Sin resultados: "No encontramos “sushi”" + sugerencias en chips.
class _NoResults extends ConsumerWidget {
  const _NoResults({required this.query, required this.onPick});

  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = (ref.watch(popularSearchesProvider).value ?? const []).take(4).map((p) => p.term).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        children: [
          AppEmptyState(
            kind: AppEmptyKind.noResults,
            title: 'No encontramos “$query”',
            message: 'Todavía no hay negocios que lo vendan cerca. Prueba con otra palabra o mira lo más pedido.',
          ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final s in suggestions) AppChip(label: s.toLowerCase(), variant: AppChipVariant.suggestion, onTap: () => onPick(s)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Resultados en pestañas: "Productos · N" y "Negocios · N".
class _Results extends ConsumerStatefulWidget {
  const _Results({required this.results, required this.onOpen, super.key});

  final SearchResults results;

  /// Se llama al abrir un resultado (guarda la búsqueda en recientes).
  final VoidCallback onOpen;

  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> with SingleTickerProviderStateMixin {
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

  /// "+" rápido: agrega sin entrar al negocio (solo si está abierto y entrega).
  Future<bool> _quickAdd(ProductHit p, StoreSummary? known) async {
    widget.onOpen();
    final summary = known ?? (await ref.read(storeDetailProvider(p.storeId).future)).summary;
    if (!mounted) return false;
    if (!summary.canOrder) {
      AppToast.show(context, summary.isOpenNow ? '${summary.name} no llega a tu dirección' : '${summary.name} está cerrado ahora');
      return false;
    }
    return addToCart(
      context,
      ref,
      line: quickCartLine(productId: p.id, name: p.name, price: p.price, imageUrl: p.imageUrl),
      store: summary.toCartStore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final results = widget.results;
    // Negocios cercanos ya cargados: dan el tiempo de entrega y la bolsa.
    final nearby = {for (final s in ref.watch(storesProvider()).value?.items ?? const <StoreSummary>[]) s.id: s};
    final stores = [
      for (final s in results.stores)
        if (!_openOnly || s.isOpenNow) s,
    ];

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
              // Productos.
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
                      enabled: entranceWindowOpen(results),
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
                        onTap: () {
                          widget.onOpen();
                          context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': p.id}).ignore();
                        },
                      ),
                    );
                  },
                ),
              // Negocios.
              ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  if (results.stores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxs),
                      child: Row(
                        children: [AppChip(label: 'Abierto ahora', selected: _openOnly, onTap: () => setState(() => _openOnly = !_openOnly))],
                      ),
                    ),
                  if (stores.isEmpty)
                    AppEmptyState(
                      kind: AppEmptyKind.noResults,
                      title: _openOnly ? 'Ninguno abierto ahora' : 'Ningún negocio con ese nombre',
                      message: _openOnly ? 'Quita el filtro o programa tu pedido.' : 'Mira la pestaña Productos.',
                      compact: true,
                    ),
                  for (final (i, s) in stores.indexed)
                    FadeSlideIn.staggered(
                      index: i,
                      enabled: entranceWindowOpen(results),
                      child: _storeRow(context, s, nearby[s.id]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _storeRow(BuildContext context, StoreHit hit, StoreSummary? summary) {
    void open() {
      widget.onOpen();
      context
          .pushNamed(
            StoreDetailPage.name,
            pathParameters: {'storeId': hit.id},
            extra: StoreRouteArgs(coverUrl: summary?.coverUrl),
          )
          .ignore();
    }

    if (summary != null) {
      return AppStoreCard(variant: AppStoreCardVariant.row, data: summary.toCardData(withDistance: true), onTap: open);
    }
    return _StoreHitRow(hit: hit, onTap: open);
  }
}

/// Respaldo cuando el negocio no está entre los cercanos ya cargados.
class _StoreHitRow extends StatelessWidget {
  const _StoreHitRow({required this.hit, required this.onTap});

  final StoreHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${hit.name}. ${hit.isOpenNow ? 'Abierto' : 'Cerrado'}. ${Formatters.eta(hit.etaMinutes)}',
      excludeSemantics: true,
      child: InkWell(
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
                        Text(Formatters.eta(hit.etaMinutes), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
