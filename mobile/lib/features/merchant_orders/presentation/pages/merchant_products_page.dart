import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(merchantProductsFilteredProvider(widget.storeId, query: _search.text, filter: _filter));
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
            Expanded(
              child: PartnerContent(
                maxWidth: 760,
                child: AsyncValueView(
                  value: catalog,
                  onRetry: () => ref.invalidate(merchantProductsProvider(widget.storeId)),
                  loading: const _ProductsSkeleton(),
                  isEmpty: (c) => c.total == 0,
                  empty: const AppEmptyState(title: 'Sin productos', message: 'Todavía no cargamos tu menú.'),
                  data: (c) => RefreshIndicator(
                    onRefresh: () => ref.refresh(merchantProductsProvider(widget.storeId).future),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                          sliver: SliverToBoxAdapter(child: _searchAndFilters(c)),
                        ),
                        if (c.visible.isEmpty)
                          const SliverToBoxAdapter(
                            child: AppEmptyState(title: 'Sin coincidencias', message: 'Prueba con otro nombre o cambia el filtro.'),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
                          sliver: SliverList.builder(
                            itemCount: c.visible.length,
                            itemBuilder: (context, index) {
                              final product = c.visible[index];
                              final section = productSection(product);
                              final startsSection = index == 0 || productSection(c.visible[index - 1]) != section;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (startsSection)
                                    Padding(
                                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                                      child: Text(section, style: Theme.of(context).textTheme.titleMedium),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                    child: _ProductRow(key: ValueKey(product.id), storeId: widget.storeId, product: product),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilters(MerchantCatalog c) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${c.available} de ${c.total} productos disponibles para pedir.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar producto',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (filter, label) in [
              (ProductFilter.all, 'Todos (${c.total})'),
              (ProductFilter.available, 'Disponibles (${c.available})'),
              (ProductFilter.soldOut, 'Agotados (${c.soldOut})'),
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
  const _ProductRow({required this.storeId, required this.product, super.key});

  final String storeId;
  final MerchantProduct product;

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> with PartnerActionRunner {
  Future<void> _toggle(bool available) =>
      run(() => ref.read(merchantProductsProvider(widget.storeId).notifier).setAvailable(widget.product, available: available));

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
    final wide = MediaQuery.sizeOf(context).width >= 360;
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
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(width: 110, height: 16),
              const SizedBox(height: AppSpacing.sm),
            ],
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
    );
  }
}
