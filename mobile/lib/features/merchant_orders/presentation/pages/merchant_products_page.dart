import 'dart:async';

import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catálogo de trabajo: buscar un producto y cambiar su disponibilidad.
class MerchantProductsPage extends ConsumerStatefulWidget {
  const MerchantProductsPage({required this.storeId, super.key});

  static const name = 'merchantProducts';
  final String storeId;

  @override
  ConsumerState<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends ConsumerState<MerchantProductsPage> {
  final _search = TextEditingController();
  ProductFilter _filter = ProductFilter.all;

  /// Lo que se manda al backend: el texto, cuando se deja de escribir.
  var _query = '';
  Timer? _debounce;

  /// La última carta recibida: mientras llega otra pestaña o búsqueda, los
  /// conteos y el buscador siguen a la vista.
  MerchantCatalog? _last;

  static const _searchDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(_searchDelay, () {
      if (mounted && text.trim() != _query) setState(() => _query = text.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _search.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = merchantCatalogProvider(widget.storeId, filter: _filter, query: _query);
    final catalog = ref.watch(provider);
    if (catalog.value case final value?) _last = value;
    final last = _last;

    final Widget body;
    if (last == null) {
      body = catalog.hasError
          ? AppEmptyState.fromError(catalog.error!, onRetry: () => ref.invalidate(provider))
          : const _ProductsSkeleton();
    } else if (last.counts.all == 0) {
      body = const AppEmptyState(scene: AppEmptyArt.menu, title: 'Sin productos', message: 'Todavía no cargamos tu menú.');
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
              sliver: SliverToBoxAdapter(child: _searchAndFilters(last.counts)),
            ),
            if (catalog.isLoading)
              const SliverToBoxAdapter(child: _ProductRowsSkeleton())
            else if (catalog.hasError)
              SliverToBoxAdapter(
                child: AppEmptyState.fromError(catalog.error!, compact: true, onRetry: () => ref.invalidate(provider)),
              )
            else if (last.sections.isEmpty)
              const SliverToBoxAdapter(
                child: AppEmptyState(
                  kind: AppEmptyKind.noResults,
                  title: 'Sin coincidencias',
                  message: 'Prueba con otro nombre o cambia el filtro.',
                ),
              )
            else
              for (final section in last.sections)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  sliver: SliverList.list(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                        child: Text(section.name, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      for (final product in section.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _ProductRow(key: ValueKey(product.id), product: product),
                        ),
                    ],
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: partnerStatusBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            PartnerPageHeader(
              eyebrow: '${brandName.toUpperCase()} SOCIOS · CARTA',
              title: 'Tu carta, ',
              accent: 'al día.',
              titleSize: 24,
            ),
            Expanded(child: PartnerContent(maxWidth: 760, child: body)),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilters(ProductCounts counts) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${counts.available} de ${counts.all} productos disponibles para pedir.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _search,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Buscar producto',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(tooltip: 'Limpiar búsqueda', icon: const Icon(Icons.close_rounded), onPressed: _clearSearch),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (filter, label) in [
              (ProductFilter.all, 'Todos (${counts.all})'),
              (ProductFilter.available, 'Disponibles (${counts.available})'),
              (ProductFilter.soldOut, 'Agotados (${counts.soldOut})'),
            ])
              AppChip(label: label, selected: _filter == filter, onTap: () => setState(() => _filter = filter)),
          ],
        ),
      ],
    );
  }
}

/// Un producto con su interruptor de disponible/agotado.
class _ProductRow extends ConsumerStatefulWidget {
  const _ProductRow({required this.product, super.key});

  final MerchantProduct product;

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> with PartnerActionRunner {
  Future<void> _toggle(bool available) =>
      run(() => ref.read(merchantProductActionsProvider.notifier).setAvailable(widget.product, available: available));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    return PartnerSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 360) ...[
            AppNetworkImage(url: product.imageUrl, width: 56, height: 64, borderRadius: AppRadius.tile),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(Formatters.money(product.price), style: theme.textTheme.bodyMedium),
                Text(
                  product.isAvailable ? 'Disponible' : 'Agotado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: product.isAvailable ? context.chaski.success : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (busy)
            const SizedBox(width: 48, child: Center(child: AppLoader(size: 22, semanticsLabel: 'Guardando')))
          else
            Semantics(
              label: 'Disponibilidad de ${product.name}',
              child: Switch(value: product.isAvailable, onChanged: _toggle),
            ),
        ],
      ),
    );
  }
}

/// La carta mientras carga: conteo, buscador, filtros y filas con foto y switch.
class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs + AppSpacing.sm, AppSpacing.gutter, 0),
      children: [
        Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 240),
              const SizedBox(height: AppSpacing.md),
              const SkeletonBox(height: 52, borderRadius: AppRadius.button),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final w in [96.0, 128.0, 112.0]) ...[
                    Flexible(child: SkeletonBox(width: w, height: 36, borderRadius: AppRadius.button)),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ],
          ),
        ),
        const _ProductRowsSkeleton(padded: false),
      ],
    );
  }
}


/// Filas de la carta en blanco: al cambiar de pestaña o buscar, solo la lista
/// espera; el buscador y los conteos quedan arriba.
class _ProductRowsSkeleton extends StatelessWidget {
  const _ProductRowsSkeleton({this.padded = true});

  /// Con el margen lateral de la lista (dentro del scroll de la carta).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 360;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padded ? AppSpacing.gutter : 0),
      child: Column(
        children: [
          const Skeleton(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                child: SkeletonBox(width: 110, height: 16),
              ),
            ),
          ),
        for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: PartnerSurface(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Skeleton(
                  child: Row(
                    children: [
                      if (wide) ...[
                        const SkeletonBox(width: 56, height: 64, borderRadius: AppRadius.tile),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 150),
                            SizedBox(height: AppSpacing.xs),
                            SkeletonBox(width: 60, height: 12),
                            SizedBox(height: 6),
                            SkeletonBox(width: 70, height: 10),
                          ],
                        ),
                      ),
                      const SkeletonBox(width: 52, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
