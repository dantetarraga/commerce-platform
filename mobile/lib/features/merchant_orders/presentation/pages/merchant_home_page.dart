import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/presentation/pages/merchant_products_page.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_orders_tab.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_rail.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_today_tab.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/store_switch.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _brand = '${brandName.toUpperCase()} SOCIOS';

bool _waiting(StaffOrder order) => order.status == OrderStatus.received;

/// Inicio del modo Negocio: pedidos nuevos (con alarma), en fogón, listos y
/// el resumen de hoy. En tablet, las tres columnas lado a lado.
class MerchantHomePage extends ConsumerWidget {
  const MerchantHomePage({super.key});

  static const name = 'merchantHome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(merchantBoardProvider);
    final storesValue = ref.watch(merchantStoresProvider);
    final stores = storesValue.value ?? const <MerchantStore>[];
    final store = stores.firstOrNull;
    final wide = PartnerLayout.isWide(context);
    final fresh = board.value?[MerchantBoardColumn.fresh]?.length ?? 0;

    final actions = [
      if (store != null)
        PartnerHeroAction(
          icon: Icons.menu_book_rounded,
          tooltip: 'Productos',
          onPressed: () => context.pushNamed(MerchantProductsPage.name, pathParameters: {'storeId': store.id}),
        ),
      const PartnerAccountButton(),
    ];

    final tabs = wide
        ? const ['Pedidos', 'Hoy']
        : [
            for (final column in MerchantBoardColumn.values)
              switch (board.value?[column]?.length ?? 0) {
                0 => column.title,
                final n => '${column.title} ($n)',
              },
            'Hoy',
          ];

    return OrderAlarmScope<StaffOrder>(
      orders: merchantActiveOrdersProvider,
      rule: const OrderAlarmRule.whilePending(_waiting),
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: partnerStatusBar(context),
          body: SafeArea(
            top: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: wide
                      ? RailHero(store: store, eyebrow: _brand, actions: actions)
                      : _KitchenHero(
                          store: store,
                          waiting: fresh,
                          actions: actions,
                          pill: stores.length == 1
                              ? StoreSwitch(store: stores.single)
                              : storesValue.isLoading && stores.isEmpty
                              ? const PartnerStatusPillSkeleton()
                              : null,
                        ),
                ),
                if (stores.length > 1) const SliverToBoxAdapter(child: StoreSwitches()),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(pinned: true, delegate: _OrderTabs(tabs)),
                ),
              ],
              body: TabBarView(
                children: [
                  if (wide)
                    RailBoard(board: board)
                  else
                    for (final column in MerchantBoardColumn.values) MerchantOrdersTab(board: board, column: column),
                  const MerchantTodayTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Buenas noches, Rosa · Tu cocina, al toque." con la foto del negocio.
class _KitchenHero extends ConsumerWidget {
  const _KitchenHero({required this.store, required this.waiting, required this.actions, this.pill});

  final MerchantStore? store;
  final int waiting;
  final List<Widget> actions;
  final Widget? pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider.select((s) => s.value));
    final summary = ref.watch(merchantSummaryProvider).value;
    final store = this.store;
    final parts = [
      if (summary != null) '${summary.totalCount} ${summary.totalCount == 1 ? 'pedido' : 'pedidos'} · ${Formatters.money(summary.sales)} hoy',
      if (waiting > 0) '$waiting por responder' else if (summary != null) 'todo al día',
    ];
    return PartnerHero(
      eyebrow: '$_brand · TU NEGOCIO',
      greeting: user == null ? null : '${partnerGreeting()}, ${user.firstName}',
      title: 'Tu negocio,',
      accent: 'al toque.',
      subtitle: summary == null ? null : parts.join(' · '),
      subtitleLoading: summary == null,
      imageUrl: store?.logoUrl,
      avatar: store == null || store.logoUrl != null ? null : const _StoreMark(),
      actions: actions,
      pill: pill,
    );
  }
}

class _StoreMark extends StatelessWidget {
  const _StoreMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
      child: Icon(Icons.soup_kitchen_rounded, size: 56, color: scheme.primary),
    );
  }
}

class _OrderTabs extends SliverPersistentHeaderDelegate {
  _OrderTabs(this.labels);

  final List<String> labels;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Align(alignment: Alignment.centerLeft, child: PartnerPillTabs(labels: labels)),
  );

  @override
  bool shouldRebuild(_OrderTabs oldDelegate) => !listEquals(oldDelegate.labels, labels);
}
