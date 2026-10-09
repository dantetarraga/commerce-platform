import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/checkout/checkout.dart';
import 'package:apamuy/features/products/products.dart';
import 'package:apamuy/features/stores/domain/entities/store_detail.dart';
import 'package:apamuy/features/stores/domain/entities/store_menu.dart';
import 'package:apamuy/features/stores/presentation/providers/stores_providers.dart';
import 'package:apamuy/features/stores/presentation/widgets/menu_search_sheet.dart';
import 'package:apamuy/features/stores/presentation/widgets/menu_section_tabs.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_detail_skeleton.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_header.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_logo.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_mappers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/async_value_view.dart';
import 'package:apamuy/shared/widgets/image_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El negocio tiene cara y nombre: portada, quién atiende y su menú.
class StoreDetailPage extends ConsumerWidget {
  const StoreDetailPage({required this.storeId, this.args = const StoreRouteArgs(), this.favorite, super.key});

  static const name = 'store-detail';

  final String storeId;
  final StoreRouteArgs args;

  /// Acción de favorito sobre la foto, si la app la ofrece.
  final Widget? favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeDetailProvider(storeId));
    return Scaffold(
      // Solo el error necesita su barra con "atrás": contenido y esqueleto traen la suya.
      appBar: store.hasError && !store.hasValue ? AppBar() : null,
      body: AsyncValueView(
        value: store,
        onRetry: () => ref.invalidate(storeDetailProvider(storeId)),
        loading: StoreDetailSkeleton(coverUrl: args.coverUrl, heroTag: args.heroTag),
        data: (value) => _StoreContent(store: value, heroTag: args.heroTag, favorite: favorite),
      ),
    );
  }
}

class _StoreContent extends ConsumerStatefulWidget {
  const _StoreContent({required this.store, this.heroTag, this.favorite});

  final StoreDetail store;
  final Object? heroTag;
  final Widget? favorite;

  @override
  ConsumerState<_StoreContent> createState() => _StoreContentState();
}

class _StoreContentState extends ConsumerState<_StoreContent> {
  final _sectionKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();

  /// Sección cuyo título ya pasó bajo la barra fija: se resalta su chip.
  final _activeSection = ValueNotifier<String?>(null);
  List<MenuSection> _sections = const [];
  var _programmaticScroll = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncActiveSection);
    ref.listenManual(storeMenuProvider(widget.store.id), (_, next) {
      if (next.value case final menu?) {
        _sections = menu.visibleSections;
        _activeSection.value ??= _sections.firstOrNull?.id;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _activeSection.dispose();
    super.dispose();
  }

  /// Alto de lo que queda fijo arriba: app bar colapsada + fila de chips.
  double get _pinnedExtent => MediaQuery.paddingOf(context).top + kToolbarHeight + MenuSectionTabsDelegate.height;

  /// Offset de scroll en el que el título de la sección toca el borde superior.
  double? _offsetOf(String sectionId) {
    final target = _sectionKeys[sectionId]?.currentContext?.findRenderObject();
    if (target == null || !target.attached) return null;
    return RenderAbstractViewport.of(target).getOffsetToReveal(target, 0).offset;
  }

  void _syncActiveSection() {
    if (_programmaticScroll || _sections.isEmpty) return;
    final line = _scroll.offset + _pinnedExtent + 1;
    var active = _sections.first.id;
    for (final section in _sections) {
      final offset = _offsetOf(section.id);
      if (offset != null && offset <= line) active = section.id;
    }
    _activeSection.value = active;
  }

  Future<void> _scrollToSection(String sectionId) async {
    final offset = _offsetOf(sectionId);
    if (offset == null || !_scroll.hasClients) return;
    _activeSection.value = sectionId;
    final target = (offset - _pinnedExtent).clamp(0.0, _scroll.position.maxScrollExtent);
    _programmaticScroll = true;
    try {
      if (reduceMotionOf(context)) {
        _scroll.jumpTo(target);
      } else {
        await _scroll.animateTo(target, duration: AppMotion.move, curve: Curves.easeInOutCubic);
      }
    } finally {
      _programmaticScroll = false;
    }
  }

  /// Se puede armar pedido: abierto, o cerrado con hora programada; y que llegue a tu zona.
  bool get _canAdd {
    final summary = widget.store.summary;
    return summary.deliversToYou && (summary.isOpenNow || ref.watch(scheduledDeliveryProvider) != null);
  }

  void _openProduct(MenuItem item) => context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': item.id});

  /// "+" rápido: solo productos sin variantes ni opciones, si se puede pedir.
  Future<bool> Function()? _quickAdd(MenuItem item, {required bool canAdd}) {
    if (item.hasChoices || !canAdd || !item.isAvailable) return null;
    return () => addToCart(
      context,
      ref,
      line: quickCartLine(productId: item.id, name: item.name, price: item.price, imageUrl: item.imageUrl),
      store: widget.store.summary.toCartStore(),
    );
  }

  void _schedule() => showScheduleSheet(
    context,
    storeName: widget.store.name,
    notBefore: widget.store.schedule.nextOpeningAt(DateTime.now()),
  ).ignore();

  void _openSearch(StoreMenu menu) => showAppBottomSheet<void>(
    context,
    size: AppSheetSize.full,
    title: 'Buscar en ${widget.store.name}',
    builder: (sheetContext) => MenuSearchSheet(
      storeId: widget.store.id,
      onOpen: (item) {
        Navigator.pop(sheetContext);
        _openProduct(item);
      },
    ),
  ).ignore();

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final summary = store.summary;
    final menu = ref.watch(storeMenuProvider(store.id));
    final canAdd = _canAdd;

    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          ImageSliverAppBar(
            title: store.name,
            imageUrl: summary.coverUrl,
            heroTag: widget.heroTag,
            dimmed: !summary.isOpenNow,
            actions: [
              if (menu case AsyncData(:final value) when !value.isEmpty)
                PhotoAction(icon: Icons.search_rounded, tooltip: 'Buscar en el menú', onPressed: () => _openSearch(value)),
            ],
            trailing: widget.favorite,
            edge: StoreLogo(logoUrl: summary.logoUrl),
            edgeHeight: StoreLogo.size,
          ),
          SliverToBoxAdapter(
            child: StoreHeader(store: store, scheduledAt: ref.watch(scheduledDeliveryProvider), onSchedule: _schedule),
          ),
          ...switch (menu) {
            AsyncData(:final value) when value.isEmpty => [
              const SliverToBoxAdapter(
                child: AppEmptyState(
                  scene: AppEmptyArt.receipt,
                  title: 'Menú en preparación',
                  message: 'Este negocio aún no publicó sus productos.',
                  compact: true,
                ),
              ),
            ],
            AsyncData(:final value) => _menuSlivers(value, canAdd: canAdd),
            AsyncError(:final error) => [
              SliverToBoxAdapter(
                child: AppEmptyState.fromError(error, compact: true, onRetry: () => ref.invalidate(storeMenuProvider(store.id))),
              ),
            ],
            _ => [
              const SliverToBoxAdapter(child: MenuHeadSkeleton()),
              SliverList.builder(itemCount: 4, itemBuilder: (_, _) => const AppProductRowSkeleton()),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  List<Widget> _menuSlivers(StoreMenu menu, {required bool canAdd}) {
    final sections = menu.visibleSections;
    final featured = menu.featured;
    // Cerrado y sin programar: la carta se ve, pero atenuada y sin "+".
    final dim = !canAdd && !widget.store.summary.isOpenNow;
    // Entrada escalonada solo al llegar el menú; el índice continúa entre secciones.
    final animate = entranceWindowOpen(menu);
    final firstIndex = <int>[];
    var running = 0;
    for (final section in sections) {
      firstIndex.add(running);
      running += section.items.length;
    }
    _MenuCard card(MenuItem item, {bool featured = false}) => _MenuCard(
      item: item,
      featured: featured,
      dimmed: dim,
      onTap: () => _openProduct(item),
      onQuickAdd: _quickAdd(item, canAdd: canAdd),
    );

    return [
      if (featured.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _MenuTitle('Lo más pedido')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => FadeSlideIn.staggered(
                index: index,
                enabled: animate,
                offset: const Offset(24, 0),
                child: card(featured[index], featured: true),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ],
      SliverPersistentHeader(
        pinned: true,
        delegate: MenuSectionTabsDelegate(sections: sections, active: _activeSection, onSelected: _scrollToSection),
      ),
      for (final (s, section) in sections.indexed) ...[
        SliverToBoxAdapter(
          key: _sectionKeys.putIfAbsent(section.id, GlobalKey.new),
          child: _MenuTitle(section.name),
        ),
        SliverList.builder(
          itemCount: section.items.length,
          itemBuilder: (context, index) => FadeSlideIn.staggered(
            index: firstIndex[s] + index,
            enabled: animate,
            child: card(section.items[index]),
          ),
        ),
      ],
    ];
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.featured, required this.dimmed, required this.onTap, this.onQuickAdd});

  final MenuItem item;
  final bool featured;
  final bool dimmed;
  final VoidCallback onTap;
  final Future<bool> Function()? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final card = AppProductCard(
      variant: featured ? AppProductCardVariant.featured : AppProductCardVariant.row,
      width: featured ? 190 : null,
      data: item.toCardData(),
      onTap: onTap,
      onQuickAdd: onQuickAdd,
    );
    return dimmed ? Opacity(opacity: 0.6, child: card) : card;
  }
}

class _MenuTitle extends StatelessWidget {
  const _MenuTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => AppSectionHeader(
    title,
    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxs),
  );
}
