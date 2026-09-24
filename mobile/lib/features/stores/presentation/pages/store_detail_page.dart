import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/presentation/providers/stores_providers.dart';
import 'package:chaski/features/stores/presentation/widgets/store_mappers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/image_sliver_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El negocio tiene cara y nombre: portada, quién atiende y su menú.
class StoreDetailPage extends ConsumerWidget {
  const StoreDetailPage({required this.storeId, this.args = const StoreRouteArgs(), super.key});

  static const name = 'store-detail';

  final String storeId;
  final StoreRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (key, child) = switch (ref.watch(storeDetailProvider(storeId))) {
      AsyncData(:final value) => ('data', _StoreContent(store: value, heroTag: args.heroTag)),
      AsyncError(:final error) => (
        'error',
        Scaffold(
          appBar: AppBar(),
          body: AppEmptyState.fromError(error, onRetry: () => ref.invalidate(storeDetailProvider(storeId))),
        ),
      ),
      _ => ('loading', _StoreDetailSkeleton(coverUrl: args.coverUrl, heroTag: args.heroTag)),
    };
    return LoadCrossFade(stateKey: key, child: child);
  }
}

/// Logo del negocio: mosaico con sombra montado sobre el borde de la hoja.
const _logoSize = 68.0;

class _StoreContent extends ConsumerStatefulWidget {
  const _StoreContent({required this.store, this.heroTag});

  final StoreDetail store;
  final Object? heroTag;

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
  }

  @override
  void dispose() {
    _scroll.dispose();
    _activeSection.dispose();
    super.dispose();
  }

  /// Alto de lo que queda fijo arriba: app bar colapsada + fila de chips.
  double get _pinnedExtent => MediaQuery.paddingOf(context).top + kToolbarHeight + _SectionTabsDelegate.height;

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
  VoidCallback? _quickAdd(MenuItem item, {required bool canAdd}) {
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
    notBefore: nextOpeningAt(widget.store.schedule, DateTime.now()),
  ).ignore();

  void _toggleFavorite() => ref.read(favoritesProvider.notifier).toggle(FavoriteKind.store, widget.store.id).ignore();

  void _openSearch(StoreMenu menu) => showAppBottomSheet<void>(
    context,
    size: AppSheetSize.full,
    title: 'Buscar en ${widget.store.name}',
    builder: (sheetContext) => _MenuSearch(
      menu: menu,
      onOpen: (item) {
        Navigator.pop(sheetContext);
        _openProduct(item);
      },
    ),
  ).ignore();

  ProductCardData _card(MenuItem item) => ProductCardData(
    id: item.id,
    name: item.name,
    description: item.description,
    imageUrl: item.imageUrl,
    price: item.price,
    isAvailable: item.isAvailable,
    fromPrice: item.hasChoices,
  );

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
                PhotoAction(
                  icon: Icons.search_rounded,
                  tooltip: 'Buscar en el menú',
                  onPressed: () => _openSearch(value),
                ),
            ],
            trailing: FavoriteButton(
              onPhoto: true,
              isFavorite: ref.watch(isFavoriteStoreProvider(store.id)),
              onPressed: _toggleFavorite,
            ),
            edge: _StoreLogo(logoUrl: summary.logoUrl),
            edgeHeight: _logoSize,
          ),
          SliverToBoxAdapter(
            child: _StoreHeader(store: store, scheduledAt: ref.watch(scheduledDeliveryProvider), onSchedule: _schedule),
          ),
          ...switch (menu) {
            AsyncData(:final value) when value.isEmpty => [
              const SliverToBoxAdapter(
                child: AppEmptyState(
                  scene: ThreadScene.receipt,
                  title: 'Menú en preparación',
                  message: 'Este negocio aún no publicó sus productos.',
                  compact: true,
                ),
              ),
            ],
            AsyncData(:final value) => _menuSlivers(value, canAdd: canAdd),
            AsyncError(:final error) => [
              SliverToBoxAdapter(
                child: AppEmptyState.fromError(
                  error,
                  compact: true,
                  onRetry: () => ref.invalidate(storeMenuProvider(store.id)),
                ),
              ),
            ],
            _ => [
              SliverList.builder(itemCount: 4, itemBuilder: (_, _) => const Skeleton(child: AppProductRowSkeleton())),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  List<Widget> _menuSlivers(StoreMenu menu, {required bool canAdd}) {
    final sections = _sections = menu.visibleSections;
    _activeSection.value ??= sections.firstOrNull?.id;
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
    Widget dimmed(Widget child) => dim ? Opacity(opacity: 0.6, child: child) : child;

    return [
      if (featured.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _SectionTitle('Lo más pedido')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = featured[index];
                return FadeSlideIn.staggered(
                  index: index,
                  enabled: animate,
                  offset: const Offset(24, 0),
                  child: dimmed(
                    AppProductCard(
                      variant: AppProductCardVariant.featured,
                      width: 190,
                      data: _card(item),
                      onTap: () => _openProduct(item),
                      onQuickAdd: _quickAdd(item, canAdd: canAdd),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ],
      SliverPersistentHeader(
        pinned: true,
        delegate: _SectionTabsDelegate(sections: sections, active: _activeSection, onSelected: _scrollToSection),
      ),
      for (final (s, section) in sections.indexed) ...[
        SliverToBoxAdapter(
          key: _sectionKeys.putIfAbsent(section.id, GlobalKey.new),
          child: _SectionTitle(section.name),
        ),
        SliverList.builder(
          itemCount: section.items.length,
          itemBuilder: (context, index) {
            final item = section.items[index];
            return FadeSlideIn.staggered(
              index: firstIndex[s] + index,
              enabled: animate,
              child: dimmed(
                AppProductCard(
                  data: _card(item),
                  onTap: () => _openProduct(item),
                  onQuickAdd: _quickAdd(item, canAdd: canAdd),
                ),
              ),
            );
          },
        ),
      ],
    ];
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: _logoSize,
      height: _logoSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(AppRadius.lg),
        boxShadow: AppShadows.raised(theme.brightness),
      ),
      child: AppNetworkImage(
        url: logoUrl,
        borderRadius: const BorderRadius.all(Radius.circular(13)),
        fallbackIcon: Icons.storefront_rounded,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxs),
    child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
  );
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store, required this.scheduledAt, required this.onSchedule});

  final StoreDetail store;
  final DateTime? scheduledAt;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = store.summary;
    final chaski = context.chaski;
    final now = DateTime.now();
    final open = summary.isOpenNow;
    final statusColor = open ? chaski.success : chaski.danger;
    final details = [
      if (open) ?closingLabelFor(store.schedule, now) else ?store.nextOpeningLabel,
      Formatters.distance(summary.distanceKm),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            hint: 'Ver horario y dirección',
            child: InkWell(
              borderRadius: const BorderRadius.all(AppRadius.md),
              onTap: () => _showAbout(context, store),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(store.name, style: theme.textTheme.headlineSmall)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: open ? '● Abierto' : '● Cerrado',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                              ),
                              for (final d in details) TextSpan(text: '  ·  $d'),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    semanticLabel: 'Sobre el negocio',
                  ),
                ],
              ),
            ),
          ),
          if (store.attendedByLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(store.attendedByLabel!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          _StatBlocks(store: store),
          if (summary.promoLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DealStrip(label: summary.promoLabel!),
          ],
          if (!summary.deliversToYou) ...[
            const SizedBox(height: AppSpacing.sm),
            const _Note(
              icon: Icons.wrong_location_outlined,
              text: 'Este negocio no llega a tu dirección. Puedes ver la carta igual.',
            ),
          ] else if (!open) ...[
            const SizedBox(height: AppSpacing.md),
            _ClosedBlock(
              scheduledAt: scheduledAt,
              canSchedule: nextOpeningAt(store.schedule, now) != null,
              onSchedule: onSchedule,
            ),
          ],
        ],
      ),
    );
  }

  void _showAbout(BuildContext context, StoreDetail store) {
    final theme = Theme.of(context);
    final summary = store.summary;
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    final today = store.schedule.hoursOn(DateTime.now());
    showAppBottomSheet<void>(
      context,
      title: store.name,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (store.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(store.description!, style: theme.textTheme.bodyMedium),
                ),
              if (store.attendedByLabel != null) row(Icons.waving_hand_outlined, store.attendedByLabel!),
              if (summary.rating.hasReviews)
                row(
                  Icons.star_rounded,
                  '${Formatters.rating(summary.rating.average)} de ${summary.rating.count} pedidos calificados',
                ),
              row(
                Icons.schedule_rounded,
                today.isEmpty
                    ? 'Hoy no abre'
                    : 'Hoy: ${today.map((h) => '${Formatters.timeOfDay(h.opensAt)} – ${Formatters.timeOfDay(h.closesAt)}').join(', ')}',
              ),
              row(Icons.place_outlined, '${store.addressLine} · a ${Formatters.distance(summary.distanceKm)}'),
              if (!summary.minOrderAmount.isZero)
                row(Icons.shopping_bag_outlined, 'Pedido mínimo ${Formatters.money(summary.minOrderAmount)}'),
            ],
          ),
        ),
      ),
    ).ignore();
  }
}

/// Tres bloques grises: calificación, tiempo y envío (con el pedido mínimo).
class _StatBlocks extends StatelessWidget {
  const _StatBlocks({required this.store});

  final StoreDetail store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = store.summary;
    final chaski = context.chaski;
    final valueStyle = AppTypography.price(context, size: 17);
    final eta = summary.etaMinutes;
    final free = summary.deliveryFee.isZero;
    final min = summary.minOrderAmount;

    Widget block({required Widget value, required String label, required String semantics}) => Expanded(
      child: Semantics(
        label: semantics,
        excludeSemantics: true,
        child: Container(
          // Misma altura para los tres aunque el de envío use dos líneas.
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: chaski.raised, borderRadius: AppRadius.tile),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              value,
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        block(
          value: summary.rating.hasReviews
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 17, color: chaski.rating),
                    const SizedBox(width: 2),
                    Text(Formatters.rating(summary.rating.average), style: valueStyle),
                  ],
                )
              : Text('Nuevo', style: valueStyle),
          label: summary.rating.hasReviews ? '${summary.rating.count} opiniones' : 'sin opiniones',
          semantics: summary.rating.hasReviews
              ? '${Formatters.rating(summary.rating.average)} estrellas, ${summary.rating.count} opiniones'
              : 'Negocio nuevo, sin opiniones aún',
        ),
        const SizedBox(width: AppSpacing.xs),
        block(
          value: Text('${eta - 5}–${eta + 5}', style: valueStyle),
          label: 'minutos',
          semantics: 'Llega en ${eta - 5} a ${eta + 5} minutos',
        ),
        const SizedBox(width: AppSpacing.xs),
        block(
          value: Text(free ? 'Gratis' : Formatters.money(summary.deliveryFee), style: valueStyle),
          // Dos líneas: en un tercio de pantalla no entra "envío · mín. S/ 12.00".
          label: min.isZero ? 'envío' : 'envío\nmín. ${_shortMoney(min)}',
          semantics: [
            if (free) 'Envío gratis' else 'Envío ${spokenMoney(summary.deliveryFee)}',
            if (!min.isZero) 'pedido mínimo ${spokenMoney(min)}',
          ].join(', '),
        ),
      ],
    );
  }

  /// "S/ 12" si no hay céntimos.
  String _shortMoney(Money m) {
    final text = Formatters.money(m);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }
}

/// Franja de oferta: relleno lima suave con texto tinta.
class _DealStrip extends StatelessWidget {
  const _DealStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    return Semantics(
      label: 'Oferta: $label',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: chaski.accentSoft, borderRadius: AppRadius.tile),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: chaski.accent, shape: BoxShape.circle),
              child: Icon(Icons.local_offer_rounded, size: 13, color: chaski.onAccent),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: chaski.onAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Negocio cerrado: en vez de un callejón sin salida, programar el pedido.
class _ClosedBlock extends StatelessWidget {
  const _ClosedBlock({required this.scheduledAt, required this.canSchedule, required this.onSchedule});

  final DateTime? scheduledAt;
  final bool canSchedule;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final at = scheduledAt;
    final (title, message) = switch ((at, canSchedule)) {
      (final at?, _) => (
        'Tu pedido va programado',
        'Te lo llevamos ${scheduledAtLabel(at, DateTime.now())}. Ya puedes armarlo.',
      ),
      (null, true) => ('Pide ahora y te lo llevamos al abrir', 'Elige la hora; te avisamos cuando salga.'),
      (null, false) => (
        'Por ahora no está atendiendo',
        'Aún no publicó su próximo horario. Puedes ver la carta igual.',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onInverseSurface)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface.withValues(alpha: 0.75)),
          ),
          if (canSchedule) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: at == null ? 'Programar pedido' : 'Cambiar hora',
              icon: Icons.schedule_rounded,
              size: AppButtonSize.md,
              onPressed: onSchedule,
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Buscador dentro del menú del negocio.
class _MenuSearch extends StatefulWidget {
  const _MenuSearch({required this.menu, required this.onOpen});

  final StoreMenu menu;
  final ValueChanged<MenuItem> onOpen;

  @override
  State<_MenuSearch> createState() => _MenuSearchState();
}

class _MenuSearchState extends State<_MenuSearch> {
  var _query = '';

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áä]'), 'a')
      .replaceAll(RegExp('[éë]'), 'e')
      .replaceAll(RegExp('[íï]'), 'i')
      .replaceAll(RegExp('[óö]'), 'o')
      .replaceAll(RegExp('[úü]'), 'u');

  @override
  Widget build(BuildContext context) {
    final q = _fold(_query.trim());
    final items = [
      for (final section in widget.menu.visibleSections)
        for (final item in section.items)
          if (q.isEmpty || _fold('${item.name} ${item.description ?? ''}').contains(q)) item,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
          child: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Chairo, gaseosa, pan…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const AppEmptyState(
                  scene: ThreadScene.search,
                  title: 'No está en la carta',
                  message: 'Prueba con otra palabra.',
                  compact: true,
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppProductCard(
                      data: ProductCardData(
                        id: item.id,
                        name: item.name,
                        description: item.description,
                        imageUrl: item.imageUrl,
                        price: item.price,
                        isAvailable: item.isAvailable,
                        fromPrice: item.hasChoices,
                      ),
                      onTap: () => widget.onOpen(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SectionTabsDelegate extends SliverPersistentHeaderDelegate {
  _SectionTabsDelegate({required this.sections, required this.active, required this.onSelected});

  final List<MenuSection> sections;
  final ValueListenable<String?> active;
  final ValueChanged<String> onSelected;

  static const height = 60.0;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: overlapsContent ? AppShadows.soft(theme.brightness) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _SectionTabs(sections: sections, active: active, onSelected: onSelected),
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionTabsDelegate oldDelegate) =>
      oldDelegate.sections != sections || oldDelegate.active != active;
}

/// Chips de secciones: el activo (tinta) se centra solo en la fila.
class _SectionTabs extends StatefulWidget {
  const _SectionTabs({required this.sections, required this.active, required this.onSelected});

  final List<MenuSection> sections;
  final ValueListenable<String?> active;
  final ValueChanged<String> onSelected;

  @override
  State<_SectionTabs> createState() => _SectionTabsState();
}

class _SectionTabsState extends State<_SectionTabs> {
  final _scroll = ScrollController();
  final _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_revealActive);
  }

  @override
  void didUpdateWidget(_SectionTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      oldWidget.active.removeListener(_revealActive);
      widget.active.addListener(_revealActive);
    }
  }

  @override
  void dispose() {
    widget.active.removeListener(_revealActive);
    _scroll.dispose();
    super.dispose();
  }

  void _revealActive() {
    final id = widget.active.value;
    final chip = id == null ? null : _chipKeys[id]?.currentContext?.findRenderObject();
    if (chip == null || !chip.attached || !_scroll.hasClients) return;
    final target = RenderAbstractViewport.of(
      chip,
    ).getOffsetToReveal(chip, 0.5).offset.clamp(0.0, _scroll.position.maxScrollExtent);
    if (reduceMotionOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: AppMotion.base, curve: AppMotion.postaOut).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.active,
      builder: (context, active, _) => ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs + 2),
        itemCount: widget.sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          return KeyedSubtree(
            key: _chipKeys.putIfAbsent(section.id, GlobalKey.new),
            child: AppChip(
              label: section.name,
              variant: AppChipVariant.choice,
              selected: section.id == active,
              onTap: () => widget.onSelected(section.id),
            ),
          );
        },
      ),
    );
  }
}

/// Misma geometría que la pantalla real (portada, cabecera, bloques, menú)
/// para que el crossfade no provoque saltos. Si la portada ya se conoce, se muestra.
class _StoreDetailSkeleton extends StatelessWidget {
  const _StoreDetailSkeleton({this.coverUrl, this.heroTag});

  final String? coverUrl;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          ImageSliverAppBar.loading(imageUrl: coverUrl, heroTag: heroTag),
          const SliverToBoxAdapter(
            child: Skeleton(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 200, height: 26),
                        SizedBox(height: 8),
                        SkeletonBox(width: 170),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(child: SkeletonBox(height: 56, borderRadius: AppRadius.tile)),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(child: SkeletonBox(height: 56, borderRadius: AppRadius.tile)),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(child: SkeletonBox(height: 56, borderRadius: AppRadius.tile)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppProductRowSkeleton(),
                  AppProductRowSkeleton(),
                  AppProductRowSkeleton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
