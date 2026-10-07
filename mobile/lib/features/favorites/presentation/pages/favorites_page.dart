import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/favorites/domain/favorites.dart';
import 'package:chaski/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Negocios y productos guardados como favoritos.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  static const name = 'favorites';

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  FavoriteKind _kind = FavoriteKind.store;

  Future<void> _remove(FavoriteKind kind, String id, String name) async {
    final notifier = ref.read(favoritesProvider.notifier);
    final result = await notifier.toggle(kind, id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        AppToast.show(
          context,
          'Quitamos $name de tus favoritos',
          actionLabel: 'Deshacer',
          onAction: () => notifier.toggle(kind, id).ignore(),
        );
      case Err(:final failure):
        AppToast.show(context, failure.message, kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
            child: Row(
              children: [
                AppChip(
                  label: 'Negocios',
                  variant: AppChipVariant.choice,
                  selected: _kind == FavoriteKind.store,
                  onTap: () => setState(() => _kind = FavoriteKind.store),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: 'Productos',
                  variant: AppChipVariant.choice,
                  selected: _kind == FavoriteKind.product,
                  onTap: () => setState(() => _kind = FavoriteKind.product),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (favorites) {
              AsyncData(:final value) => _List(kind: _kind, ids: value.idsOf(_kind).toList(), onRemove: _remove),
              AsyncError(:final error) => AppEmptyState.fromError(error, onRetry: () => ref.invalidate(favoritesProvider)),
              _ => const Skeleton(child: Column(children: [_RowSkeleton(), _RowSkeleton(), _RowSkeleton()])),
            },
          ),
        ],
      ),
    );
  }
}

typedef _OnRemove = Future<void> Function(FavoriteKind kind, String id, String name);

class _List extends StatelessWidget {
  const _List({required this.kind, required this.ids, required this.onRemove});

  final FavoriteKind kind;
  final List<String> ids;
  final _OnRemove onRemove;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return switch (kind) {
        FavoriteKind.store => const AppEmptyState(
          title: 'Aún no guardas negocios',
          message: 'Toca el corazón de tu picantería o bodega de confianza y la tendrás aquí, a un toque.',
        ),
        FavoriteKind.product => const AppEmptyState(
          title: 'Aún no guardas productos',
          message: 'Ese chairo que siempre pides: guárdalo con el corazón y lo encuentras aquí.',
        ),
      };
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: ids.length,
      itemBuilder: (context, index) => switch (kind) {
        FavoriteKind.store => _StoreRow(key: ValueKey(ids[index]), storeId: ids[index], onRemove: onRemove),
        FavoriteKind.product => _ProductRow(key: ValueKey(ids[index]), productId: ids[index], onRemove: onRemove),
      },
    );
  }
}

class _StoreRow extends ConsumerWidget {
  const _StoreRow({required this.storeId, required this.onRemove, super.key});

  final String storeId;
  final _OnRemove onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(storeDetailProvider(storeId))) {
      AsyncData(:final value) => _FavoriteRow(
        imageUrl: value.summary.coverUrl ?? value.summary.logoUrl,
        title: value.name,
        fallbackIcon: Icons.storefront_rounded,
        meta: StoreMetaLine(data: value.summary.toCardData()),
        onTap: () => context.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': storeId}),
        onRemove: () => onRemove(FavoriteKind.store, storeId, value.name),
      ),
      // Un favorito que ya no existe no ensucia la lista.
      AsyncError() => const SizedBox.shrink(),
      _ => const Skeleton(child: _RowSkeleton()),
    };
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.productId, required this.onRemove, super.key});

  final String productId;
  final _OnRemove onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return switch (ref.watch(productDetailProvider(productId))) {
      AsyncData(:final value) => _FavoriteRow(
        imageUrl: value.imageUrl,
        title: value.name,
        fallbackIcon: Icons.fastfood_rounded,
        meta: Row(
          children: [
            Flexible(
              child: Text(value.storeName, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppPrice(value.basePrice, variant: value.hasVariants ? AppPriceVariant.from : AppPriceVariant.regular, size: 14),
          ],
        ),
        onTap: () => context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': productId}),
        onRemove: () => onRemove(FavoriteKind.product, productId, value.name),
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const Skeleton(child: _RowSkeleton()),
    };
  }
}

/// Fila: foto, nombre, meta y corazón relleno para quitar.
class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.imageUrl,
    required this.title,
    required this.fallbackIcon,
    required this.meta,
    required this.onTap,
    required this.onRemove,
  });

  final String? imageUrl;
  final String title;
  final IconData fallbackIcon;
  final Widget meta;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
          child: Row(
            children: [
              AppNetworkImage(url: imageUrl, width: 64, height: 64, borderRadius: AppRadius.tile, fallbackIcon: fallbackIcon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    meta,
                  ],
                ),
              ),
              FavoriteButton(isFavorite: true, onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
    child: Row(
      children: [
        SkeletonBox(width: 64, height: 64, borderRadius: AppRadius.tile),
        SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SkeletonBox(width: 170, height: 16), SizedBox(height: 8), SkeletonBox(width: 120)],
        ),
      ],
    ),
  );
}
