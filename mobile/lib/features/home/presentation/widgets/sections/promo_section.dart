import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/features/discovery/discovery.dart';
import 'package:apamuy/features/home/presentation/widgets/editorial_promos.dart';
import 'package:apamuy/features/home/presentation/widgets/open_store.dart';
import 'package:apamuy/features/products/products.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Esta noche en Yauri": primero un producto que se agrega con "+", luego las promos.
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
        openStore(context, promo.storeId!);
      } else if (promo.couponCode != null) {
        AppToast.show(context, 'Usa el código ${promo.couponCode} en tu bolsa.');
      }
    }

    final night = ref.watch(currentMomentProvider) == Moment.night;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(night ? 'Esta noche en $cityName' : 'Hoy en $cityName', subtitle: 'Promos de negocios cerca de ti'),
        LoadCrossFade(
          stateKey: items == null ? 'loading' : 'data',
          child: items == null
              ? const EditorialPromosSkeleton()
              : EditorialPromos(promotions: items, onTap: onTap, leading: lead == null ? null : _LeadProduct(product: lead)),
        ),
      ],
    );
  }
}

/// Producto de la ciudad que abre el carril, con "+" rápido.
class _LeadProduct extends ConsumerWidget {
  const _LeadProduct({required this.product});

  final ProductHit product;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: 212,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.apamuy.card, borderRadius: AppRadius.card),
    child: AppProductCard(
      width: 188,
      variant: AppProductCardVariant.featured,
      data: ProductCardData(
        id: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        subtitle: product.storeName,
      ),
      onQuickAdd: () => quickAddProduct(context, ref, product),
      onTap: () => context.pushNamed(ProductDetailPage.name, pathParameters: {'productId': product.id}),
    ),
  );
}
