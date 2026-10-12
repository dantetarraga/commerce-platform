import 'dart:async';

import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/merchant_catalog/merchant_catalog.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant.dart';
import 'package:apamuy/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La carta del negocio: buscar, marcar disponible o agotado, poner la foto
/// que falta, editar rápido, elegir varios y entrar a crear, ordenar secciones
/// o importar un Excel. En tablet, la edición va en un panel al lado.
class MerchantProductsPage extends ConsumerStatefulWidget {
  const MerchantProductsPage({required this.storeId, super.key});

  static const name = 'merchantProducts';
  final String storeId;

  /// Desde este ancho, lista y edición lado a lado.
  static const twoPaneWidth = 1000.0;

  @override
  ConsumerState<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

/// Lo que muestra el panel lateral en tablet.
sealed class _Pane {
  const _Pane();
}

final class _NewProductPane extends _Pane {
  const _NewProductPane();
}

final class _ProductPane extends _Pane {
  const _ProductPane(this.productId);

  final String productId;
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

  /// Elegidos con un toque largo; con alguno, la lista está en modo de elegir.
  final _selected = <String>{};

  _Pane? _pane;

  static const _searchDelay = Duration(milliseconds: 300);

  bool get _selecting => _selected.isNotEmpty;

  bool get _twoPane => MediaQuery.sizeOf(context).width >= MerchantProductsPage.twoPaneWidth;

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

  Map<String, String> get _store => {'storeId': widget.storeId};

  void _newProduct() {
    if (_twoPane) {
      setState(() => _pane = const _NewProductPane());
    } else {
      unawaited(context.pushNamed(ProductEditorPage.newName, pathParameters: _store));
    }
  }

  void _import() => unawaited(context.pushNamed(ProductImportPage.name, pathParameters: _store));

  void _sections() => unawaited(context.pushNamed(MenuSectionsPage.name, pathParameters: _store));

  /// Tocar el filtro activo vuelve a mostrar todos.
  void _toggleFilter(ProductFilter filter) => setState(() => _filter = _filter == filter ? ProductFilter.all : filter);

  void _open(MerchantProduct product) {
    if (_selecting) return _toggleSelected(product.id);
    if (_twoPane) {
      setState(() => _pane = _ProductPane(product.id));
    } else {
      unawaited(showQuickEditSheet(context, storeId: widget.storeId, productId: product.id));
    }
  }

  void _toggleSelected(String productId) {
    HapticFeedback.selectionClick().ignore();
    setState(() => _selected.contains(productId) ? _selected.remove(productId) : _selected.add(productId));
  }

  void _selectAll(MerchantCatalog catalog) => setState(
    () => _selected.addAll([
      for (final s in catalog.sections)
        for (final p in s.items) p.id,
    ]),
  );

  void _clearSelection() => setState(_selected.clear);

  @override
  Widget build(BuildContext context) {
    final provider = merchantCatalogProvider(widget.storeId, filter: _filter, query: _query);
    final catalog = ref.watch(provider);
    final highlights = ref.watch(importHighlightsProvider);
    if (catalog.value case final value?) _last = value;
    final last = _last;
    final theme = Theme.of(context);

    final Widget body;
    if (last == null) {
      body = catalog.hasError
          ? AppEmptyState.fromError(catalog.error!, onRetry: () => ref.invalidate(provider))
          : const _ProductsSkeleton();
    } else if (last.counts.all == 0) {
      body = MenuStartOptions(onImport: _import, onCreate: _newProduct);
    } else {
      final selectedId = switch (_pane) {
        _ProductPane(:final productId) => productId,
        _ => null,
      };
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
              sliver: SliverToBoxAdapter(child: _searchAndFilters(last.counts, highlights.length)),
            ),
            if (catalog.isLoading)
              const SliverToBoxAdapter(child: _ProductRowsSkeleton())
            else if (catalog.hasError)
              SliverToBoxAdapter(
                child: AppEmptyState.fromError(catalog.error!, compact: true, onRetry: () => ref.invalidate(provider)),
              )
            else if (last.sections.isEmpty)
              SliverToBoxAdapter(
                child: _filter == ProductFilter.noPhoto && _query.isEmpty
                    ? const AppEmptyState(
                        kind: AppEmptyKind.noResults,
                        title: 'Todos tienen foto',
                        message: 'Tu carta se ve completa en la app.',
                      )
                    : const AppEmptyState(
                        kind: AppEmptyKind.noResults,
                        title: 'Sin coincidencias',
                        message: 'Prueba con otro nombre o cambia el filtro.',
                      ),
              )
            else
              for (final section in last.sections)
                // El nombre de la sección queda arriba mientras se recorren sus productos.
                SliverMainAxisGroup(
                  slivers: [
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.sm,
                            AppSpacing.gutter,
                            AppSpacing.xs,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(section.name, style: theme.textTheme.titleMedium),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
                      sliver: SliverList.list(
                        children: [
                          for (final product in section.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _ProductRow(
                                key: ValueKey(product.id),
                                storeId: widget.storeId,
                                product: product,
                                selecting: _selecting,
                                selected: _selected.contains(product.id) || product.id == selectedId,
                                imported: ref.read(importHighlightsProvider.notifier).of(product.name),
                                onTap: () => _open(product),
                                onLongPress: () => _toggleSelected(product.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      );
    }

    final empty = last != null && last.counts.all == 0;
    final Widget? bottom;
    if (empty) {
      bottom = null;
    } else if (_selecting) {
      bottom = MenuBottomBar(
        child: MenuBulkBar(storeId: widget.storeId, productIds: _selected.toList(), onDone: _clearSelection),
      );
    } else {
      bottom = MenuBottomBar(
        child: AppButton(label: 'Nuevo producto', icon: Icons.add_rounded, onPressed: _newProduct),
      );
    }

    final header = _selecting
        ? _SelectionHeader(
            count: _selected.length,
            onCancel: _clearSelection,
            onSelectAll: last == null ? null : () => _selectAll(last),
          )
        : PartnerPageHeader(
            eyebrow: '${brandName.toUpperCase()} SOCIOS · CARTA',
            title: 'Tu carta, ',
            accent: 'al día.',
            titleSize: 24,
            trailing: [_MenuOptions(onSections: _sections, onImport: _import)],
          );

    final list = Scaffold(
      appBar: partnerStatusBar(context),
      bottomNavigationBar: bottom,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            header,
            Expanded(child: PartnerContent(maxWidth: 760, child: body)),
          ],
        ),
      ),
    );

    final pane = _pane;
    final Widget page;
    if (_twoPane && !empty) {
      page = Row(
        children: [
          SizedBox(width: 480, child: list),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: switch (pane) {
              null => const _PaneHint(),
              _NewProductPane() => ProductEditorPage(
                key: const ValueKey('new'),
                storeId: widget.storeId,
                onDone: () => setState(() => _pane = null),
              ),
              _ProductPane(:final productId) => ProductEditorPage(
                key: ValueKey(productId),
                storeId: widget.storeId,
                productId: productId,
                onDone: () => setState(() => _pane = null),
              ),
            },
          ),
        ],
      );
    } else {
      page = list;
    }

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: page,
    );
  }

  Widget _searchAndFilters(ProductCounts counts, int imported) {
    final tiles = [
      (ProductFilter.available, '${counts.available}/${counts.all}', 'disponibles', _Tone.plain),
      (
        ProductFilter.soldOut,
        '${counts.soldOut}',
        counts.soldOut == 1 ? 'agotado' : 'agotados',
        counts.soldOut == 0 ? _Tone.plain : _Tone.danger,
      ),
      (ProductFilter.noPhoto, '${counts.noPhoto}', 'sin foto', counts.noPhoto == 0 ? _Tone.plain : _Tone.accent),
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (imported > 0) ...[
          _ImportedNotice(count: imported, onDismiss: () => ref.read(importHighlightsProvider.notifier).clear()),
          const SizedBox(height: AppSpacing.sm),
        ],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (filter, value, label, tone)) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _FilterTile(
                    value: value,
                    label: label,
                    tone: tone,
                    selected: _filter == filter,
                    onTap: () => _toggleFilter(filter),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
        if (!_selecting) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mantén presionado un producto para elegir varios.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Cabecera mientras se eligen productos: cuántos, todos y cancelar.
class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.count, required this.onCancel, required this.onSelectAll});

  final int count;
  final VoidCallback onCancel;
  final VoidCallback? onSelectAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.header),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancelar',
            color: scheme.onInverseSurface,
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                count == 1 ? '1 elegido' : '$count elegidos',
                style: AppTypography.displayStyle(context, size: 22).copyWith(color: scheme.onInverseSurface),
              ),
            ),
          ),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(foregroundColor: scheme.onInverseSurface),
            child: const Text('Todos'),
          ),
        ],
      ),
    );
  }
}

/// Aviso tras importar: los productos que entraron quedan resaltados.
class _ImportedNotice extends StatelessWidget {
  const _ImportedNotice({required this.count, required this.onDismiss});

  final int count;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.tile),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: scheme.onPrimaryContainer, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                count == 1
                    ? 'Resaltamos el producto que importaste. Revísalo.'
                    : 'Resaltamos los $count productos que importaste. Revísalos.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
            TextButton(onPressed: onDismiss, child: const Text('Listo')),
          ],
        ),
      ),
    );
  }
}

/// El panel de tablet antes de elegir un producto.
class _PaneHint extends StatelessWidget {
  const _PaneHint();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: AppEmptyState(
      scene: AppEmptyArt.menu,
      title: 'Elige un producto',
      message: 'Lo editas aquí mismo, sin salir de la carta.',
    ),
  );
}

/// Menú ⋯ de la cabecera: lo que se usa de vez en cuando.
class _MenuOptions extends StatelessWidget {
  const _MenuOptions({required this.onSections, required this.onImport});

  final VoidCallback onSections;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Más opciones de la carta',
      position: PopupMenuPosition.under,
      onSelected: (action) => action(),
      style: IconButton.styleFrom(
        backgroundColor: scheme.inverseSurface,
        foregroundColor: scheme.onInverseSurface,
        fixedSize: const Size.square(AppSpacing.minTouch),
      ),
      icon: const Icon(Icons.more_horiz_rounded),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onSections,
          child: const ListTile(leading: Icon(Icons.reorder_rounded), title: Text('Secciones')),
        ),
        PopupMenuItem(
          value: onImport,
          child: const ListTile(leading: Icon(Icons.upload_file_rounded), title: Text('Importar Excel o CSV')),
        ),
      ],
    );
  }
}

enum _Tone { plain, danger, accent }

/// Un conteo de la carta que también filtra la lista.
class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.value,
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final _Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueColor = selected
        ? scheme.onInverseSurface
        : switch (tone) {
            _Tone.plain => scheme.onSurface,
            _Tone.danger => scheme.error,
            _Tone.accent => scheme.primary,
          };
    return Semantics(
      button: true,
      selected: selected,
      label: '$value $label',
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.inverseSurface : context.apamuy.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.tile,
          side: BorderSide(color: selected ? scheme.inverseSurface : scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.price(context).copyWith(color: valueColor)),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected ? scheme.onInverseSurface : scheme.onSurfaceVariant,
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

/// Un producto con su interruptor de disponible/agotado; en modo de elegir,
/// con una casilla.
class _ProductRow extends ConsumerStatefulWidget {
  const _ProductRow({
    required this.storeId,
    required this.product,
    required this.selecting,
    required this.selected,
    required this.imported,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final String storeId;
  final MerchantProduct product;
  final bool selecting;
  final bool selected;

  /// Entró con la última importación.
  final ImportAction? imported;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> with PartnerActionRunner {
  Future<void> _toggle(bool available) async {
    HapticFeedback.selectionClick().ignore();
    final product = widget.product;
    final ok = await run(
      () => ref.read(merchantProductActionsProvider.notifier).setAvailable(product, available: available),
    );
    if (!ok || !mounted) return;
    // Un toque sin querer deja un producto agotado en plena atención.
    AppToast.show(
      context,
      available ? '${product.name}: disponible otra vez.' : '${product.name}: agotado.',
      kind: AppToastKind.undo,
      onAction: () => unawaited(
        ref.read(merchantProductActionsProvider.notifier).setAvailable(product, available: !available),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final product = widget.product;
    final imported = widget.imported;
    return PartnerSurface(
      padding: EdgeInsets.zero,
      highlighted: widget.selected || imported != null,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: AppRadius.tile,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              if (product.imageUrl case final url? when url.isNotEmpty)
                AppNetworkImage(url: url, width: 56, height: 56, borderRadius: AppRadius.tile)
              else
                QuickPhotoButton(storeId: widget.storeId, productId: product.id, productName: product.name),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          product.isAvailable
                              ? Formatters.money(product.price)
                              : 'Agotado · ${Formatters.money(product.price)}',
                          style: product.isAvailable
                              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)
                              : theme.textTheme.bodyMedium?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
                        ),
                        if (imported != null)
                          Text(
                            imported == ImportAction.create ? 'Nuevo' : 'Cambió',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (widget.selecting)
                Checkbox(
                  value: widget.selected,
                  semanticLabel: 'Elegir ${product.name}',
                  onChanged: (_) => widget.onTap(),
                )
              else if (busy)
                const SizedBox(width: 48, child: Center(child: AppLoader(size: 22, semanticsLabel: 'Guardando')))
              else
                Semantics(
                  label: 'Disponibilidad de ${product.name}',
                  child: Switch(value: product.isAvailable, onChanged: _toggle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La carta mientras carga: conteos, buscador y filas con foto y switch.
class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs + AppSpacing.sm, AppSpacing.gutter, 0),
      children: const [
        Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 60, borderRadius: AppRadius.tile)),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(child: SkeletonBox(height: 60, borderRadius: AppRadius.tile)),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(child: SkeletonBox(height: 60, borderRadius: AppRadius.tile)),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 52, borderRadius: AppRadius.button),
            ],
          ),
        ),
        _ProductRowsSkeleton(padded: false),
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
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: PartnerSurface(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Skeleton(
                  child: Row(
                    children: [
                      SkeletonBox(width: 56, height: 56, borderRadius: AppRadius.tile),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 150),
                            SizedBox(height: AppSpacing.xs),
                            SkeletonBox(width: 60, height: 12),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 52, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
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
