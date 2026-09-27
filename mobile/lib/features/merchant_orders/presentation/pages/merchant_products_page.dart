import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
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

enum _ProductFilter { all, available, soldOut }

class _MerchantProductsPageState extends ConsumerState<MerchantProductsPage> {
  final _search = TextEditingController();
  final Set<String> _saving = {};
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(MerchantProduct product, bool available) async {
    setState(() => _saving.add(product.id));
    final failure = await ref
        .read(merchantProductsProvider(widget.storeId).notifier)
        .setAvailable(product, available: available);
    if (!mounted) return;
    setState(() => _saving.remove(product.id));
    if (failure != null) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(merchantProductsProvider(widget.storeId));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: theme.colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(28)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHASKI SOCIOS · CARTA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text.rich(
              TextSpan(
                text: 'Tu carta, ',
                children: [TextSpan(text: 'al día.', style: TextStyle(color: theme.colorScheme.primary))],
              ),
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: PartnerContent(
          maxWidth: 760,
          child: AsyncValueView(
            value: products,
            onRetry: () => ref.invalidate(merchantProductsProvider(widget.storeId)),
            loading: const Center(child: CircularProgressIndicator()),
            isEmpty: (list) => list.isEmpty,
            empty: const AppEmptyState(
              title: 'Sin productos',
              message: 'Todavía no cargamos tu menú.',
            ),
            data: (list) {
              final available = list.where((p) => p.isAvailable).length;
              final query = _search.text.trim().toLowerCase();
              final filtered =
                  list
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(query) &&
                            switch (_filter) {
                              _ProductFilter.all => true,
                              _ProductFilter.available => p.isAvailable,
                              _ProductFilter.soldOut => !p.isAvailable,
                            },
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.section ?? 'Otros').compareTo(
                        b.section ?? 'Otros',
                      ),
                    );
              return RefreshIndicator(
                onRefresh: () => ref.refresh(
                  merchantProductsProvider(widget.storeId).future,
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xs,
                        AppSpacing.gutter,
                        AppSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '$available de ${list.length} productos disponibles para pedir.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Buscar producto',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: query.isEmpty
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
                                  (
                                    _ProductFilter.all,
                                    'Todos (${list.length})',
                                  ),
                                  (
                                    _ProductFilter.available,
                                    'Disponibles ($available)',
                                  ),
                                  (
                                    _ProductFilter.soldOut,
                                    'Agotados (${list.length - available})',
                                  ),
                                ])
                                  AppChip(
                                    label: label,
                                    selected: _filter == filter,
                                    onTap: () => setState(() => _filter = filter),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      const SliverToBoxAdapter(
                        child: AppEmptyState(
                          title: 'Sin coincidencias',
                          message: 'Prueba con otro nombre o cambia el filtro.',
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        0,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final section = product.section ?? 'Otros';
                          final startsSection = index == 0 || (filtered[index - 1].section ?? 'Otros') != section;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (startsSection)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.md,
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    section,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: PartnerSurface(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      if (MediaQuery.sizeOf(context).width >= 360) ...[
                                        AppNetworkImage(
                                          url: product.imageUrl,
                                          width: 56,
                                          height: 64,
                                          borderRadius: AppRadius.tile,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.xxs,
                                            ),
                                            Text(
                                              Formatters.money(product.price),
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              product.isAvailable ? 'Disponible' : 'Agotado',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: product.isAvailable
                                                    ? context.chaski.success
                                                    : theme.colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      if (_saving.contains(product.id))
                                        const SizedBox(
                                          width: 48,
                                          child: Center(
                                            child: SizedBox.square(
                                              dimension: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Semantics(
                                          label: 'Disponibilidad de ${product.name}',
                                          child: Switch(
                                            value: product.isAvailable,
                                            onChanged: (value) => _toggle(product, value),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
