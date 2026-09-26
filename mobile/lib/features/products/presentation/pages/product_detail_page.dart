import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:chaski/features/products/domain/entities/product_selection.dart';
import 'package:chaski/features/products/presentation/providers/cart_line_mapper.dart';
import 'package:chaski/features/products/presentation/providers/products_providers.dart';
import 'package:chaski/features/products/presentation/widgets/option_group.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/image_sliver_app_bar.dart';
import 'package:chaski/shared/widgets/quantity_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalle de producto: la foto manda, las opciones son filas claras y abajo
/// queda fija la cantidad con "Agregar · total".
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, super.key});

  static const name = 'product-detail';

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (key, child) = switch (ref.watch(productDetailProvider(productId))) {
      AsyncData(:final value) => ('data', _ProductContent(product: value)),
      AsyncError(:final error) => (
        'error',
        Scaffold(
          appBar: AppBar(),
          body: AppEmptyState.fromError(error, onRetry: () => ref.invalidate(productDetailProvider(productId))),
        ),
      ),
      _ => ('loading', const _ProductDetailSkeleton()),
    };
    return LoadCrossFade(stateKey: key, child: child);
  }
}

class _ProductContent extends ConsumerStatefulWidget {
  const _ProductContent({required this.product});

  static const imageHeight = 320.0;

  final Product product;

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
      Scrollable.ensureVisible(target, duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move, curve: AppMotion.arrive)
          .ignore();
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
            trailing: FavoriteButton(
              onPhoto: true,
              isFavorite: ref.watch(isFavoriteProductProvider(product.id)),
              onPressed: () => ref.read(favoritesProvider.notifier).toggle(FavoriteKind.product, product.id).ignore(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(product.name, style: theme.textTheme.headlineSmall)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(product.storeName, style: theme.textTheme.bodySmall),
                  if (product.description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(product.description!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // El dominio aún no trae precio anterior: cuando llegue, AppPriceVariant.discount.
                  AppPrice(selection.unitPrice, size: 22),
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
      bottomNavigationBar: _AddBar(
        selection: selection,
        open: open,
        adding: _adding,
        onQuantityChanged: controller.setQuantity,
        onAdd: () => selection.isValid ? _add(selection) : _revealMissing(selection),
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({
    required this.selection,
    required this.open,
    required this.adding,
    required this.onQuantityChanged,
    required this.onAdd,
  });

  final ProductSelection selection;
  final bool open;
  final bool adding;
  final ValueChanged<Quantity> onQuantityChanged;
  final VoidCallback onAdd;

  String? get _hint {
    if (!open) return 'Está cerrado ahora. Programa tu pedido desde el negocio y lo agregas.';
    if (!selection.product.isAvailable) return 'Este producto se agotó por hoy.';
    if (selection.needsVariant) return 'Elige un tamaño.';
    final missing = selection.missingRequiredOptions;
    if (missing.isNotEmpty) return 'Falta elegir: ${missing.map((o) => o.name).join(', ')}.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _hint;
    final canTry = open && selection.product.isAvailable;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        // La sombra suave, hacia arriba.
        boxShadow: [
          for (final s in AppShadows.soft(theme.brightness))
            BoxShadow(color: s.color, blurRadius: s.blurRadius, offset: Offset(0, -s.offset.dy)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                curve: AppMotion.arrive,
                alignment: Alignment.bottomCenter,
                child: hint == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: SizedBox(width: double.infinity, child: Text(hint, style: theme.textTheme.bodySmall)),
                      ),
              ),
              Row(
                children: [
                  QuantityStepper(quantity: selection.quantity, onChanged: onQuantityChanged, enabled: canTry),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AddButton(
                      total: Formatters.money(selection.total),
                      enabled: canTry,
                      valid: selection.isValid,
                      loading: adding,
                      onAdd: onAdd,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Agregar · total" en cobalto; el total cambia con una transición corta.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.total,
    required this.enabled,
    required this.valid,
    required this.loading,
    required this.onAdd,
  });

  final String total;
  final bool enabled;
  final bool valid;
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Incompleto: se ve más suave pero responde (lleva al grupo que falta).
    final bg = enabled ? (valid ? scheme.primary : scheme.primary.withValues(alpha: 0.55)) : context.chaski.raised;
    final fg = enabled ? scheme.onPrimary : scheme.onSurfaceVariant;
    final reduce = reduceMotionOf(context);
    final style = theme.textTheme.labelLarge?.copyWith(color: fg, fontSize: 16, fontWeight: FontWeight.w800);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Agregar a la bolsa, $total',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: AppRadius.button,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !loading ? onAdd : null,
          child: SizedBox(
            height: 56,
            child: Center(
              child: loading
                  ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Agregar · ', style: style),
                        AnimatedSwitcher(
                          duration: reduce ? Duration.zero : AppMotion.quick,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            total,
                            key: ValueKey(total),
                            style: style?.copyWith(fontFeatures: AppTypography.tabularFigures),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
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
