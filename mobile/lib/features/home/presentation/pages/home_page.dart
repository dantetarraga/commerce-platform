import 'package:apamuy/features/discovery/discovery.dart';
import 'package:apamuy/features/home/presentation/widgets/active_order_cover/active_order_cover.dart';
import 'package:apamuy/features/home/presentation/widgets/header/home_header.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/barrio_stores.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/category_shelf.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/promo_section.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/recommended_stores.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/repeat_row.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/while_you_wait.dart';
import 'package:apamuy/features/notifications/notifications.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inicio: portada, categorías, promos, volver a pedir, recomendados y negocios
/// cerca. Con un pedido en curso, la portada es su seguimiento.
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
      ..invalidate(noticeFeedProvider);
    await ref.read(storesProvider(sort: StoreSort.popular).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activeOrderProvider).value;
    final live = order != null && order.isActive;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
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
                SliverToBoxAdapter(child: RepeatRow(onExplore: () => context.goNamed(HomePage.name))),
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
