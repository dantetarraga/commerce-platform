import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/home/presentation/pages/home_page.dart';
import 'package:chaski/features/home/presentation/widgets/city_categories.dart';
import 'package:chaski/features/home/presentation/widgets/home_editorial.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void _openStore(
  BuildContext context,
  String storeId, {
  String? coverUrl,
  Object? heroTag,
}) => context.pushNamed(
  StoreDetailPage.name,
  pathParameters: {'storeId': storeId},
  extra: StoreRouteArgs(coverUrl: coverUrl, heroTag: heroTag),
);

/// Título de sección: Outfit, con "Ver todo" en cobalto si hay a dónde ir.
/// Deja 32 arriba: las secciones se separan por aire, no por líneas.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {this.subtitle, this.onSeeAll, super.key});

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.section,
        onSeeAll == null ? AppSpacing.gutter : AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouch,
                  AppSpacing.minTouch,
                ),
              ),
              child: Text(
                'Ver todo',
                semanticsLabel: 'Ver todo: $title',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dos destinos principales y un carril de categorías ordenado por momento.
class CategoryShelf extends ConsumerWidget {
  const CategoryShelf({super.key});

  /// Orden de los 4 principales (por `slug`); si falta alguno, entra el siguiente.
  static const _main = [
    'restaurantes',
    'mercado',
    'farmacia',
    'bodegas',
    'postres',
    'licores',
    'regalos',
    'encargos',
  ];

  /// Elige los 4 accesos y cuál resaltar según el momento.
  static ({List<Category> main, List<Category> rest, String? highlighted}) pick(
    List<Category> all,
    Moment moment,
  ) {
    int rank(Category c) {
      final i = _main.indexOf(c.slug);
      return i < 0 ? _main.length : i;
    }

    final sorted = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
    final main = sorted.take(4).toList();
    // Si la categoría del momento no está entre las 4, reemplaza a la última.
    final featured = moment.featuredCategories
        .map((slug) => all.where((c) => c.slug == slug).firstOrNull)
        .nonNulls
        .firstOrNull;
    if (featured != null && !main.contains(featured) && main.length == 4) {
      main[3] = featured;
    }
    return (
      main: main,
      rest: [
        for (final c in sorted)
          if (!main.contains(c)) c,
      ],
      highlighted: featured?.slug,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(currentMomentProvider);
    final categories = ref.watch(categoriesProvider);
    final openCount = <String, int>{};
    for (final store
        in ref.watch(storesProvider()).value?.items ?? const <StoreSummary>[]) {
      if (!store.isOpenNow) continue;
      for (final id in store.categoryIds) {
        openCount[id] = (openCount[id] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: LoadCrossFade(
        stateKey: categories.hasValue
            ? 'data'
            : (categories.hasError ? 'error' : 'loading'),
        child: switch (categories) {
          AsyncValue(:final value?) => CityCategories(
            categories: [
              ...pick(value, moment).main,
              ...pick(value, moment).rest,
            ],
            highlighted: pick(value, moment).highlighted,
            openCount: openCount,
          ),
          AsyncError(:final error) => Padding(
            padding: AppSpacing.screen,
            child: AppEmptyState.fromError(
              error,
              compact: true,
              onRetry: () => ref.invalidate(categoriesProvider),
            ),
          ),
          _ => const CityCategoriesSkeleton(),
        },
      ),
    );
  }
}

/// "Volver a pedir": tarjetas con foto, cuántas veces lo pediste y acción rápida.
/// Oculta si no hay historial.
class RepeatRow extends ConsumerWidget {
  const RepeatRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(recentOrdersByStoreProvider).value ?? const [];
    if (orders.isEmpty) return const SizedBox.shrink();
    final history = ref.watch(ordersHistoryProvider).value ?? const [];
    final times = <String, int>{};
    for (final o in history) {
      if (o.status == OrderStatus.delivered) {
        times[o.store.id] = (times[o.store.id] ?? 0) + 1;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle('Volver a pedir'),
        RepeatShelf(
          orders: orders,
          timesByStore: times,
          onOpen: (order) => _openStore(context, order.store.id),
          onRepeat: (order) => _repeatOrder(context, ref, order),
        ),
      ],
    );
  }
}

/// Negocio del barrio. Si está cerrado dice cuándo abre y ofrece programar el pedido
/// (el horario viene en el detalle, que solo se pide para los cerrados).
class _BarrioStoreCard extends ConsumerWidget {
  const _BarrioStoreCard({required this.store});

  final StoreSummary store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = storeCoverHeroTag(store.id, 'barrio');
    final closedLabel = store.isOpenNow
        ? null
        : ref.watch(storeDetailProvider(store.id)).value?.nextOpeningLabel;
    void open() =>
        _openStore(context, store.id, coverUrl: store.coverUrl, heroTag: tag);
    return AppStoreCard(
      variant: AppStoreCardVariant.editorial,
      heroTag: tag,
      isFavorite: ref.watch(isFavoriteStoreProvider(store.id)),
      onFavoriteToggle: () => ref
          .read(favoritesProvider.notifier)
          .toggle(FavoriteKind.store, store.id)
          .ignore(),
      data: store.toCardData(withDistance: true, closedLabel: closedLabel),
      onSchedule: store.isOpenNow ? null : open,
      onTap: open,
    );
  }
}

/// Agrega a la bolsa un producto sin opciones desde el inicio.
Future<bool> _quickAddProduct(
  BuildContext context,
  WidgetRef ref,
  ProductHit product,
) async {
  final store = (await ref.read(
    storeDetailProvider(product.storeId).future,
  )).summary;
  if (!context.mounted) return false;
  if (!store.canOrder) {
    AppToast.show(
      context,
      store.isOpenNow
          ? '${store.name} no llega a tu dirección'
          : '${store.name} está cerrado ahora',
    );
    return false;
  }
  return addToCart(
    context,
    ref,
    line: quickCartLine(
      productId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
    ),
    store: store.toCartStore(),
  );
}

/// "Esta noche en Yauri": primero un producto que se agrega con "+", luego las promos
/// en formatos que se alternan.
class PromoCarouselSection extends ConsumerWidget {
  const PromoCarouselSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotions = ref.watch(promotionsProvider);
    final items = promotions.value;
    final products = ref.watch(localProductsProvider).value ?? const [];
    final lead = products.where((p) => !p.hasChoices).firstOrNull;
    if (promotions.hasError || (items != null && items.isEmpty && lead == null)) {
      return const SizedBox.shrink();
    }

    void onTap(Promotion promo) {
      if (promo.storeId != null) {
        _openStore(context, promo.storeId!);
      } else if (promo.couponCode != null) {
        AppToast.show(
          context,
          'Usa el código ${promo.couponCode} en tu bolsa.',
        );
      }
    }

    final night = DateTime.now().hour >= 18;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(
          night ? 'Esta noche en Yauri' : 'Hoy en Yauri',
          subtitle: 'Promos de negocios cerca de ti',
        ),
        LoadCrossFade(
          stateKey: items == null ? 'loading' : 'data',
          child: items == null
              ? const EditorialPromosSkeleton()
              : EditorialPromos(
                  promotions: items,
                  onTap: onTap,
                  leading: lead == null
                      ? null
                      : Container(
                          width: 212,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? context.chaski.raised
                                : AppColors.blanco,
                            borderRadius: AppRadius.card,
                          ),
                          child: AppProductCard(
                            width: 188,
                            variant: AppProductCardVariant.featured,
                            data: ProductCardData(
                              id: lead.id,
                              name: lead.name,
                              price: lead.price,
                              imageUrl: lead.imageUrl,
                              subtitle: lead.storeName,
                            ),
                            onQuickAdd: () =>
                                _quickAddProduct(context, ref, lead),
                            onTap: () => context.pushNamed(
                              ProductDetailPage.name,
                              pathParameters: {'productId': lead.id},
                            ),
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

/// "Recomendados para ti": filas con foto cuadrada, lo principal (tiempo y envío)
/// arriba y lo secundario (distancia y mínimo) debajo.
class RecommendedStores extends ConsumerWidget {
  const RecommendedStores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref
        .watch(storesProvider(sort: StoreSort.popular))
        .value
        ?.items
        .where((s) => s.isOpenNow)
        .take(3)
        .toList();
    if (stores == null || stores.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle('Recomendados para ti'),
        for (final (i, store) in stores.indexed) ...[
          if (i > 0)
            const Padding(padding: AppSpacing.screen, child: Divider()),
          Semantics(
            button: true,
            label: store.toCardData(withDistance: true).name,
            onTap: () =>
                _openStore(context, store.id, coverUrl: store.coverUrl),
            excludeSemantics: true,
            child: InkWell(
              onTap: () =>
                  _openStore(context, store.id, coverUrl: store.coverUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: store.coverUrl,
                      width: 84,
                      height: 84,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(6),
                      ),
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            store.rating.hasReviews
                                ? '★ ${store.rating.average.toStringAsFixed(1)} · ${store.rating.count} opiniones'
                                : 'Nuevo en $brandName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${Formatters.eta(store.etaMinutes)} · ',
                                ),
                                if (store.deliveryFee.isZero)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.chaski.accent,
                                        borderRadius: AppRadius.button,
                                      ),
                                      child: Text(
                                        'Envío gratis',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: context.chaski.onAccent,
                                            ),
                                      ),
                                    ),
                                  )
                                else
                                  TextSpan(
                                    text:
                                        '${Formatters.money(store.deliveryFee)} envío',
                                  ),
                              ],
                            ),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${Formatters.distance(store.distanceKm)} · '
                            '${store.minOrderAmount.isZero ? 'sin mínimo' : 'mínimo ${Formatters.money(store.minOrderAmount)}'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mientras hay un pedido en curso: buscar algo más y cuatro accesos.
class WhileYouWait extends ConsumerWidget {
  const WhileYouWait({super.key});

  static String _waitLabel(Category c) =>
      c.slug == 'restaurantes' ? 'Comida' : categoryShelfLabel(c.slug, c.name);

  static const _slugs = ['restaurantes', 'bodegas', 'farmacia', 'encargos'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final picked = [
      for (final slug in _slugs)
        ?categories.where((c) => c.slug == slug).firstOrNull,
    ];
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hints: const [
              '¿Algo más mientras esperas?',
              'Busca comida, tiendas o productos',
            ],
            variant: AppSearchBarVariant.compact,
            onTap: () => context.goNamed(ExplorePage.name),
          ),
          if (picked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                'Mientras esperas',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final (i, c) in picked.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Explorar ${_waitLabel(c)}',
                      excludeSemantics: true,
                      onTap: () => context.pushNamed(
                        CategoryStoresPage.name,
                        pathParameters: {'categoryId': c.id},
                      ),
                      child: Material(
                        color: c.slug == 'encargos'
                            ? AppColors.terracota
                            : (dark
                                  ? context.chaski.raised
                                  : (i.isOdd
                                        ? AppColors.hierbaSoft
                                        : AppColors.terracota50)),
                        borderRadius: AppRadius.button,
                        child: InkWell(
                          borderRadius: AppRadius.button,
                          onTap: () => context.pushNamed(
                            CategoryStoresPage.name,
                            pathParameters: {'categoryId': c.id},
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 76),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    categoryVisuals(c.slug).icon,
                                    color: c.slug == 'encargos'
                                        ? AppColors.blanco
                                        : (dark
                                              ? theme.colorScheme.onSurface
                                              : AppColors.tinta),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _waitLabel(c),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: c.slug == 'encargos'
                                              ? AppColors.blanco
                                              : (dark
                                                    ? theme
                                                          .colorScheme
                                                          .onSurface
                                                    : AppColors.tinta),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _StoreFilter {
  open('Abierto ahora'),
  freeDelivery('Envío gratis'),
  topRated('★ 4.5 o más');

  const _StoreFilter(this.label);
  final String label;

  bool accepts(StoreSummary s) => switch (this) {
    open => s.isOpenNow,
    freeDelivery => s.deliveryFee.isZero,
    topRated => s.rating.hasReviews && s.rating.average >= 4.5,
  };
}

/// "Cerca de ti": negocios por cercanía con filtros rápidos; foto amplia y datos
/// en dos niveles. Los cerrados dicen cuándo abren y ofrecen programar.
class BarrioStores extends ConsumerStatefulWidget {
  const BarrioStores({super.key});

  @override
  ConsumerState<BarrioStores> createState() => _BarrioStoresState();
}

class _BarrioStoresState extends ConsumerState<BarrioStores> {
  final _filters = <_StoreFilter>{};

  @override
  Widget build(BuildContext context) {
    final provider = storesProvider();
    final stores = ref.watch(provider);
    final all = stores.value?.items ?? const <StoreSummary>[];
    final open = all.where((s) => s.isOpenNow).length;
    final shown = all
        .where((s) => _filters.every((f) => f.accepts(s)))
        .toList();
    final scheme = Theme.of(context).colorScheme;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionTitle(
                'Cerca de ti',
                subtitle: stores.hasValue
                    ? '$open ${open == 1 ? 'negocio abierto' : 'negocios abiertos'} ahora'
                    : null,
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.screen,
                  itemCount: _StoreFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = _StoreFilter.values[index];
                    final on = _filters.contains(f);
                    return Semantics(
                      button: true,
                      toggled: on,
                      label: 'Filtro ${f.label}',
                      excludeSemantics: true,
                      onTap: () => setState(
                        () => on ? _filters.remove(f) : _filters.add(f),
                      ),
                      child: Material(
                        color: on ? scheme.primary : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.button,
                          side: BorderSide(
                            color: on ? scheme.primary : scheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: AppRadius.button,
                          onTap: () => setState(
                            () => on ? _filters.remove(f) : _filters.add(f),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text(
                                f.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: on
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        switch (stores) {
          AsyncValue(hasValue: true) when shown.isEmpty =>
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.gutter),
                child: AppEmptyState(
                  title: 'Nada con esos filtros',
                  message: 'Prueba quitando alguno.',
                  compact: true,
                ),
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
            child: AppEmptyState.fromError(
              error,
              compact: true,
              onRetry: () => ref.invalidate(provider),
            ),
          ),
          _ => SliverList.builder(
            itemCount: 2,
            itemBuilder: (_, _) => const AppStoreCardSkeleton(
              variant: AppStoreCardVariant.editorial,
            ),
          ),
        },
      ],
    );
  }
}

Future<void> _repeatOrder(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final router = GoRouter.of(context);
  final StoreSummary store;
  try {
    store = (await ref.read(
      storeDetailProvider(order.store.id).future,
    )).summary;
  } on Object {
    if (context.mounted) {
      AppToast.show(
        context,
        'No pudimos cargar ${order.store.name}. Intenta de nuevo.',
        kind: AppToastKind.error,
      );
    }
    return;
  }
  if (!context.mounted) return;
  if (!store.canOrder) {
    AppToast.show(
      context,
      store.isOpenNow
          ? '${store.name} no llega a tu dirección'
          : '${store.name} está cerrado ahora',
    );
    _openStore(context, store.id, coverUrl: store.coverUrl);
    return;
  }

  final lines = <CartLine>[];
  var missing = 0;
  for (final (i, line) in order.lines.indexed) {
    final productId = line.productId;
    if (productId == null) {
      missing++;
      continue;
    }
    final Product product;
    try {
      product = await ref.read(productDetailProvider(productId).future);
    } on Object {
      missing++;
      continue;
    }
    final parts = line.description
        .split(' · ')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    // Por nombre; si el pedido no lo guardó, la del precio pagado o la primera disponible.
    final paid = line.quantity > 0
        ? line.total.cents ~/ line.quantity
        : line.total.cents;
    final available = product.variants.where((v) => v.isAvailable);
    final variant =
        product.variants.where((v) => parts.contains(v.name)).firstOrNull ??
        available.where((v) => v.price.cents == paid).firstOrNull ??
        available.firstOrNull;
    final choices = [
      for (final option in product.options)
        for (final value in option.values)
          if (parts.contains(value.name) && value.isAvailable)
            CartChoice(
              optionId: option.id,
              valueId: value.id,
              label: value.name,
              priceDelta: value.priceDelta,
            ),
    ];
    final quantity = Quantity.create(line.quantity);
    if (!product.isAvailable ||
        (variant != null && !variant.isAvailable) ||
        quantity is! Valid<Quantity>) {
      missing++;
      continue;
    }
    final unit = choices.fold(
      variant?.price ?? product.basePrice,
      (sum, c) => sum + c.priceDelta,
    );
    lines.add(
      CartLine(
        id: '$productId.${DateTime.now().microsecondsSinceEpoch}.$i',
        productId: productId,
        name: product.name,
        imageUrl: product.imageUrl,
        variantId: variant?.id,
        variantName: variant?.name,
        choices: choices,
        unitPrice: unit,
        quantity: quantity.value,
        notes: line.notes,
      ),
    );
  }
  if (!context.mounted) return;
  if (lines.isEmpty) {
    AppToast.show(
      context,
      'Lo de ese pedido ya no está disponible. Mira qué hay hoy.',
    );
    _openStore(context, store.id, coverUrl: store.coverUrl);
    return;
  }

  final controller = ref.read(cartControllerProvider.notifier);
  final cartStore = store.toCartStore();
  final first = await controller.add(lines.first, cartStore);
  if (!context.mounted) return;
  if (first case StoreConflict(:final current, :final incoming)) {
    final replace = await confirmReplaceCart(
      context,
      current: current,
      incoming: incoming,
    );
    if (!replace || !context.mounted) return;
    await controller.replaceWith(lines.first, cartStore);
  }
  for (final line in lines.skip(1)) {
    await controller.add(line, cartStore);
  }
  if (!context.mounted) return;
  HapticFeedback.lightImpact().ignore();
  AppToast.show(
    context,
    missing == 0
        ? 'Tu pedido de ${store.name} va en tu bolsa'
        : 'Agregamos lo disponible; $missing ${missing == 1 ? 'producto ya no está' : 'productos ya no están'}',
    kind: AppToastKind.success,
  );
  showCartSheet(
    context,
    onCheckout: () => router.pushNamed(CheckoutPage.name).ignore(),
    onExplore: () => router.goNamed(HomePage.name),
  ).ignore();
}
