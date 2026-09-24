import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/home/presentation/widgets/home_sections.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/profile/profile.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Cerca": dirección y avisos, el saludo, el buscador, los 4 accesos por tipo
/// de negocio, el carrusel de promos, volver a pedir, las ofertas de hoy y los
/// negocios cercanos.
///
/// Solo compone: cada sección lee los providers públicos de su feature.
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CercaHeader(onProfile: () => context.goNamed(ProfilePage.name))),
              const SliverToBoxAdapter(child: CercaGreeting()),
              const SliverToBoxAdapter(child: CercaSearch()),
              const SliverToBoxAdapter(child: CategoryShelf()),
              const SliverToBoxAdapter(child: PromoCarouselSection()),
              const SliverToBoxAdapter(child: RepeatRow()),
              const SliverToBoxAdapter(child: OffersRow()),
              const SliverToBoxAdapter(child: NearbyCollection()),
              const BarrioStores(),
              const SliverToBoxAdapter(child: LocalProductsRow()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}
