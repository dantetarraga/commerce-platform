import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void _openStore(BuildContext context, String storeId, {String? coverUrl, Object? heroTag}) => context.pushNamed(
  StoreDetailPage.name,
  pathParameters: {'storeId': storeId},
  extra: StoreRouteArgs(coverUrl: coverUrl, heroTag: heroTag),
);

void _openCategory(BuildContext context, Category c) =>
    context.pushNamed(CategoryStoresPage.name, pathParameters: {'categoryId': c.id});

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
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.section, onSeeAll == null ? AppSpacing.gutter : AppSpacing.xs, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
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
              style: TextButton.styleFrom(minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch)),
              child: Text(
                'Ver todo',
                semanticsLabel: 'Ver todo: $title',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Entregar en Jr. Tacna 214 ▾" (abre la hoja de direcciones) + campana con
/// punto lima si hay avisos sin leer + acceso a "Tú".
class CercaHeader extends ConsumerWidget {
  const CercaHeader({required this.onProfile, super.key});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final address = ref.watch(selectedAddressProvider);
    final location = ref.watch(currentDeliveryLocationProvider);
    final user = ref.watch(authSessionProvider).value;
    final unread = ref.watch(unreadNoticesCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.xs, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Entregar en ${address?.street ?? location.label}. Cambiar dirección',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: const BorderRadius.all(AppRadius.md),
                onTap: () => showAddressPicker(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entregar en', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Row(
                        children: [
                          Icon(
                            address == null ? Icons.near_me_rounded : addressIcon(address.kind),
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              address?.street ?? location.label,
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _BellButton(unread: unread),
          IconButton(
            tooltip: 'Tú',
            onPressed: onProfile,
            icon: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.initials, seed: user?.id, size: 36),
          ),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
      onPressed: () => context.pushNamed(NotificationsPage.name),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(unread == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded, color: theme.colorScheme.onSurface),
          if (unread > 0)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.chaski.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "¿Qué se te antoja, Alex?" en una sola línea.
class CercaGreeting extends ConsumerWidget {
  const CercaGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(authSessionProvider).value?.firstName;
    final text = name == null || name.isEmpty ? '¿Qué se te antoja hoy?' : '¿Qué se te antoja, $name?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class CercaSearch extends ConsumerWidget {
  const CercaSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(currentMomentProvider);
    return Padding(
      padding: AppSpacing.screen,
      child: AppSearchBar(hints: moment.searchHints, onTap: () => context.goNamed(ExplorePage.name)),
    );
  }
}

/// 4 accesos grandes por tipo de negocio; el del momento del día va resaltado.
/// El resto de categorías queda en una fila discreta de chips.
class CategoryShelf extends ConsumerWidget {
  const CategoryShelf({super.key});

  /// Orden de los 4 principales (por `slug`); si falta alguno, entra el siguiente.
  static const _main = ['restaurantes', 'mercado', 'farmacia', 'bodegas', 'postres', 'licores', 'regalos', 'encargos'];

  /// Nombre corto para el mosaico ("Restaurantes" no entra: es "Comida").
  static String _label(Category c) => switch (c.slug) {
    'restaurantes' => 'Comida',
    'bodegas' => 'Tiendas',
    _ => categoryShelfLabel(c.slug, c.name),
  };

  /// Elige los 4 accesos y cuál resaltar según el momento.
  static ({List<Category> main, List<Category> rest, String? highlighted}) pick(List<Category> all, Moment moment) {
    int rank(Category c) {
      final i = _main.indexOf(c.slug);
      return i < 0 ? _main.length : i;
    }

    final sorted = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
    final main = sorted.take(4).toList();
    // Si la categoría del momento no está entre las 4, reemplaza a la última.
    final featured = moment.featuredCategories.map((slug) => all.where((c) => c.slug == slug).firstOrNull).nonNulls.firstOrNull;
    if (featured != null && !main.contains(featured) && main.length == 4) main[3] = featured;
    return (
      main: main,
      rest: [for (final c in sorted) if (!main.contains(c)) c],
      highlighted: featured?.slug,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(currentMomentProvider);
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: LoadCrossFade(
        stateKey: categories.hasValue ? 'data' : (categories.hasError ? 'error' : 'loading'),
        child: switch (categories) {
          AsyncValue(:final value?) => _Shelf(picked: pick(value, moment), moment: moment),
          AsyncError(:final error) => Padding(
            padding: AppSpacing.screen,
            child: AppEmptyState.fromError(error, compact: true, onRetry: () => ref.invalidate(categoriesProvider)),
          ),
          _ => Padding(
            padding: AppSpacing.screen,
            child: Skeleton(
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    const Expanded(child: SkeletonBox(height: 92, borderRadius: BorderRadius.all(AppRadius.lg))),
                  ],
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.picked, required this.moment});

  final ({List<Category> main, List<Category> rest, String? highlighted}) picked;
  final Moment moment;

  String? _caption(Category c) => switch ((moment, c.slug)) {
    (Moment.lunch, 'restaurantes') => 'Menú del día desde S/ 12',
    (Moment.night, 'restaurantes') => 'Caldos y sopas',
    (Moment.breakfast, 'mercado') => 'Pan de horno de leña',
    (Moment.afternoon, 'postres') => 'Tortas y café de altura',
    (_, 'farmacia') => 'Boticas abiertas cerca',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            children: [
              for (final (i, c) in picked.main.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: SizedBox(
                    height: 92,
                    child: FadeSlideIn.staggered(
                      index: i,
                      enabled: entranceWindowOpen(picked.main),
                      child: AppCategory(
                        label: CategoryShelf._label(c),
                        icon: categoryVisuals(c.slug).icon,
                        size: c.slug == picked.highlighted ? AppCategorySize.large : AppCategorySize.small,
                        caption: c.slug == picked.highlighted ? _caption(c) : null,
                        onTap: () => _openCategory(context, c),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (picked.rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            child: Row(
              children: [
                for (final (i, c) in picked.rest.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: CategoryShelf._label(c),
                    icon: categoryVisuals(c.slug).icon,
                    variant: AppChipVariant.suggestion,
                    onTap: () => _openCategory(context, c),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Volver a pedir": una fila-card con el último pedido entregado y su total.
/// Oculta si no hay historial.
class RepeatRow extends ConsumerWidget {
  const RepeatRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = (ref.watch(recentOrdersByStoreProvider).value ?? const []).firstOrNull;
    if (order == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = order.lines.map((l) => l.name).join(', ');
    final summary = items.isEmpty ? order.store.name : '${order.store.name} · $items';
    final total = Formatters.money(order.total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.section, AppSpacing.gutter, 0),
      child: Semantics(
        button: true,
        label: 'Volver a pedir. $summary. Total $total',
        excludeSemantics: true,
        child: PressableScale(
          child: Material(
            color: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openStore(context, order.store.id),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: order.store.logoUrl,
                      width: 52,
                      height: 52,
                      borderRadius: AppRadius.tile,
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Volver a pedir', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(summary, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: const BorderRadius.all(AppRadius.pill)),
                      child: Text(total, style: AppTypography.price(context, size: 14).copyWith(color: scheme.onPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Promociones: carrusel de banners justo debajo de las categorías.
class PromoCarouselSection extends ConsumerWidget {
  const PromoCarouselSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotions = ref.watch(promotionsProvider);
    final items = promotions.value;
    if (promotions.hasError || (items != null && items.isEmpty)) return const SizedBox.shrink();

    void onTap(Promotion promo) {
      if (promo.storeId != null) {
        _openStore(context, promo.storeId!);
      } else if (promo.couponCode != null) {
        AppToast.show(context, 'Usa el código ${promo.couponCode} en tu bolsa.');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: LoadCrossFade(
        stateKey: items == null ? 'loading' : 'data',
        child: items == null
            ? const Skeleton(child: PromotionsCarouselSkeleton())
            : PromotionsCarousel(promotions: items, onTap: onTap),
      ),
    );
  }
}

/// "Ofertas de hoy": negocios abiertos con una promo vigente (la cinta va en la foto).
class OffersRow extends ConsumerWidget {
  const OffersRow({super.key});

  static const _heroSource = 'offers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider(sort: StoreSort.popular)).value;
    final offers = stores?.items.where((s) => s.promoLabel != null && s.isOpenNow).toList();
    if (offers == null || offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle('Ofertas de hoy', subtitle: 'Descuentos y envíos gratis cerca'),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final store = offers[index];
              final tag = storeCoverHeroTag(store.id, _heroSource);
              return AppStoreCard(
                data: store.toCardData(),
                heroTag: tag,
                onTap: () => _openStore(context, store.id, coverUrl: store.coverUrl, heroTag: tag),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Cerca de ti": cards con foto, primero las del momento del día.
class NearbyCollection extends ConsumerWidget {
  const NearbyCollection({super.key});

  static const _heroSource = 'nearby';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(currentMomentProvider);
    final provider = storesProvider(sort: StoreSort.popular);
    final stores = ref.watch(provider);
    final picked = stores.value?.items.where((s) => s.isOpenNow).toList()
      ?..sort((a, b) => (b.tags.contains(moment.tag) ? 1 : 0).compareTo(a.tags.contains(moment.tag) ? 1 : 0));
    if (picked != null && picked.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle('Cerca de ti', subtitle: moment.collectionTitle),
        SizedBox(
          height: 206,
          child: LoadCrossFade(
            stateKey: picked == null ? (stores.hasError ? 'error' : 'loading') : 'data',
            child: picked == null
                ? (stores.hasError
                      ? AppEmptyState.fromError(stores.error!, compact: true, onRetry: () => ref.invalidate(provider))
                      : Skeleton(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: AppSpacing.screen,
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [AppStoreCardSkeleton(), SizedBox(width: AppSpacing.sm), AppStoreCardSkeleton()],
                          ),
                        ))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.screen,
                    itemCount: picked.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final store = picked[index];
                      final tag = storeCoverHeroTag(store.id, _heroSource);
                      return FadeSlideIn.staggered(
                        index: index,
                        enabled: entranceWindowOpen(stores.value!),
                        offset: const Offset(24, 0),
                        child: AppStoreCard(
                          data: store.toCardData(),
                          heroTag: tag,
                          onTap: () => _openStore(context, store.id, coverUrl: store.coverUrl, heroTag: tag),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// "De tu barrio": negocios por cercanía con pedido mínimo (sliver).
class BarrioStores extends ConsumerWidget {
  const BarrioStores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storesProvider();
    final stores = ref.watch(provider);
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: HomeSectionTitle('De tu barrio', subtitle: 'Ordenados por cercanía')),
        switch (stores) {
          AsyncValue(:final value?) => SliverList.builder(
            itemCount: value.items.length,
            itemBuilder: (context, index) {
              final store = value.items[index];
              return FadeSlideIn.staggered(
                index: index,
                enabled: entranceWindowOpen(value),
                child: AppStoreCard(
                  variant: AppStoreCardVariant.row,
                  data: store.toCardData(withDistance: true),
                  onTap: () => _openStore(context, store.id, coverUrl: store.coverUrl),
                ),
              );
            },
          ),
          AsyncError(:final error) => SliverToBoxAdapter(
            child: AppEmptyState.fromError(error, compact: true, onRetry: () => ref.invalidate(provider)),
          ),
          _ => SliverList.builder(
            itemCount: 3,
            itemBuilder: (_, _) => const Skeleton(child: AppStoreCardSkeleton(variant: AppStoreCardVariant.row)),
          ),
        },
      ],
    );
  }
}

/// "Hecho en Espinar": productos de la ciudad.
class LocalProductsRow extends ConsumerWidget {
  const LocalProductsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(localProductsProvider).value;
    if (products == null || products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle('Hecho en Espinar', subtitle: 'Queso, pan y sabores de aquí'),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final p = products[index];
              return AppProductCard(
                variant: AppProductCardVariant.tile,
                data: ProductCardData(id: p.id, name: p.name, price: p.price, imageUrl: p.imageUrl, subtitle: p.storeName, fromPrice: p.hasChoices),
                onTap: () => context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': p.id}),
              );
            },
          ),
        ),
      ],
    );
  }
}
