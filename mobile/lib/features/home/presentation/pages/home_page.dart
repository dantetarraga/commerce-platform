import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/home/presentation/widgets/home_editorial.dart';
import 'package:chaski/features/home/presentation/widgets/home_header.dart';
import 'package:chaski/features/home/presentation/widgets/home_sections.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/orders/orders_customer.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inicio: portada con dirección y buscador, categorías, promos, volver a pedir,
/// recomendados y negocios cerca. Con un pedido en curso, la portada es su
/// seguimiento y debajo aparece "Mientras esperas".
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const name = 'home';

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(categoriesProvider)
      ..invalidate(promotionsProvider)
      ..invalidate(storesProvider)
      ..invalidate(localProductsProvider)
      ..invalidate(ordersHistoryProvider)
      ..invalidate(notificationsProvider);
    await ref.read(storesProvider(sort: StoreSort.popular).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activeOrderProvider).value;
    final live = order != null && order.isActive;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RefreshIndicator(
            color: AppColors.terracota,
            backgroundColor: AppColors.blanco,
            edgeOffset: MediaQuery.paddingOf(context).top + 60,
            onRefresh: () => _refresh(ref),
            child: CustomScrollView(
              key: const PageStorageKey('city-home'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                HomeHeader(
                  compactOnly: live,
                  onHelp: live ? () => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': order.id}) : null,
                ),
                if (live) ...[
                  SliverToBoxAdapter(
                    child: ActiveOrderCover(key: ValueKey(order.id), order: order),
                  ),
                  const SliverToBoxAdapter(child: WhileYouWait()),
                ] else
                  const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.only(top: 6), child: CategoryShelf()),
                  ),
                const SliverToBoxAdapter(child: PromoCarouselSection()),
                const SliverToBoxAdapter(child: RepeatRow()),
                const SliverToBoxAdapter(child: RecommendedStores()),
                const BarrioStores(),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
