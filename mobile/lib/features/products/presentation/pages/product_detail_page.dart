import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/checkout/checkout.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/domain/entities/product_selection.dart';
import 'package:apamuy/features/products/domain/mappers/selection_to_cart_line.dart';
import 'package:apamuy/features/products/presentation/providers/products_providers.dart';
import 'package:apamuy/features/products/presentation/widgets/option_group.dart';
import 'package:apamuy/features/products/presentation/widgets/product_add_bar.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/async_value_view.dart';
import 'package:apamuy/shared/widgets/image_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalle de producto: la foto manda, las opciones son filas claras y abajo
/// queda fija la cantidad con "Agregar · total".
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, this.favorite, super.key});

  static const name = 'product-detail';

  final String productId;

  /// Acción de favorito sobre la foto, si la app la ofrece.
  final Widget? favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailProvider(productId));
    return Scaffold(
      // Solo el error necesita su barra con "atrás": contenido y esqueleto traen la suya.
      appBar: product.hasError && !product.hasValue ? AppBar() : null,
      body: AsyncValueView(
        value: product,
        onRetry: () => ref.invalidate(productDetailProvider(productId)),
        loading: const _ProductDetailSkeleton(),
        data: (value) => _ProductContent(product: value, favorite: favorite),
      ),
    );
  }
}

class _ProductContent extends ConsumerStatefulWidget {
  const _ProductContent({required this.product, this.favorite});

  static const imageHeight = 320.0;

  final Product product;
  final Widget? favorite;

  @override
  ConsumerState<_ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends ConsumerState<_ProductContent> {
  final GlobalKey _imageKey = GlobalKey();
  final _groupKeys = <String, GlobalKey>{};
  var _adding = false;

  Product get product => widget.product;

  /// Lleva la vista al primer grupo obligatorio sin elegir.
  void _revealMissing(ProductSelection selection) {
    final missingId = selection.needsVariant ? '_variant' : selection.missingRequiredOptions.firstOrNull?.id;
    final target = missingId == null ? null : _groupKeys[missingId]?.currentContext;
    HapticFeedback.mediumImpact().ignore();
    if (target != null) {
      Scrollable.ensureVisible(target, duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move, curve: AppMotion.arrive).ignore();
    }
  }

  Future<void> _add(ProductSelection selection) async {
    final store = product.store;
    if (store == null || _adding) return;
    setState(() => _adding = true);
    final added = await addToCart(
      context,
      ref,
      line: selection.toCartLine(),
      store: CartStore(
        id: product.storeId,
        name: product.storeName,
        logoUrl: store.logoUrl,
        deliveryFee: store.deliveryFee,
        minOrderAmount: store.minOrderAmount,
        etaMinutes: store.etaMinutes,
      ),
    );
    if (!mounted) return;
    if (!added) {
      setState(() => _adding = false);
      return;
    }
    // El traspaso: la foto viaja a la barra de compra y la pantalla se cierra.
    final from = globalRectOf(_imageKey);
    if (from != null) await flyToPurchaseBar(context, from: from.deflate(from.width * 0.2), imageUrl: product.imageUrl);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = productSelectionControllerProvider(product);
    final selection = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    // Cerrado se puede armar igual si el pedido va programado.
    final open = (product.store?.isOpenNow ?? true) || ref.watch(scheduledDeliveryProvider) != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ImageSliverAppBar(
            key: _imageKey,
            title: product.name,
            imageUrl: product.imageUrl,
            expandedHeight: _ProductContent.imageHeight,
            fallbackIcon: Icons.fastfood_rounded,
            leadingIcon: Icons.close_rounded,
            trailing: widget.favorite,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARMA TU PEDIDO', style: AppTypography.eyebrow(context)),
                  const SizedBox(height: 8),
                  Semantics(header: true, child: Text(product.name, style: theme.textTheme.headlineLarge)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(product.storeName, style: theme.textTheme.bodySmall),
                  if (product.description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(product.description!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppPrice(selection.unitPrice, size: 28),
                  if (!product.isAvailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const AppBadge(AppBadgeStatus.closed, label: 'Agotado por hoy'),
                  ],
                ],
              ),
            ),
          ),
          if (product.hasVariants)
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _groupKeys.putIfAbsent('_variant', GlobalKey.new),
                child: VariantGroup(variants: product.variants, selectedId: selection.variantId, onSelected: controller.selectVariant),
              ),
            ),
          for (final option in product.options)
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _groupKeys.putIfAbsent(option.id, GlobalKey.new),
                child: OptionGroup(
                  option: option,
                  selection: selection,
                  onToggle: (valueId) => controller.toggleValue(option.id, valueId),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.md),
              child: AppInput(
                label: 'Indicaciones (opcional)',
                variant: AppInputVariant.note,
                maxLength: ProductSelection.maxNotesLength,
                onChanged: controller.setNotes,
                hint: 'Ej.: sin cebolla, cremas aparte',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
      bottomNavigationBar: ProductAddBar(
        selection: selection,
        open: open,
        adding: _adding,
        onQuantityChanged: controller.setQuantity,
        onAdd: () => selection.isValid ? _add(selection) : _revealMissing(selection),
      ),
    );
  }
}

/// Misma geometría que la pantalla real: portada a sangre + textos + opciones.
class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        ImageSliverAppBar.loading(expandedHeight: _ProductContent.imageHeight, leadingIcon: Icons.close_rounded),
        SliverToBoxAdapter(
          child: Skeleton(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 240, height: 28),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90),
                  SizedBox(height: 12),
                  SkeletonLines(),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 90, height: 26),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonBox(height: 52, borderRadius: AppRadius.tile),
                  SizedBox(height: 8),
                  SkeletonBox(height: 52, borderRadius: AppRadius.tile),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
