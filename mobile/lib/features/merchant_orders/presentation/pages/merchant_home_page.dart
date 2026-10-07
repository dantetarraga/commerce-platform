import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/pages/merchant_products_page.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_order_card.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_brand.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inicio del modo Negocio: pedidos nuevos (con alarma), en preparación,
/// listos y el resumen de hoy.
class MerchantHomePage extends ConsumerStatefulWidget {
  const MerchantHomePage({super.key});

  static const name = 'merchantHome';

  @override
  ConsumerState<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends ConsumerState<MerchantHomePage> {
  late final OrderAlarm _alarm;

  @override
  void initState() {
    super.initState();
    _alarm = ref.read(orderAlarmProvider);
    _alarm.keepAwake(on: true).ignore();
  }

  @override
  void dispose() {
    _alarm
      ..silence().ignore()
      ..keepAwake(on: false).ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Suena mientras haya pedidos nuevos sin responder.
    ref.listen(merchantActiveOrdersProvider, (_, next) {
      final orders = next.value;
      if (orders == null) return;
      if (orders.any((o) => o.status == OrderStatus.received)) {
        _alarm.ring().ignore();
      } else {
        _alarm.silence().ignore();
      }
    });

    final orders = ref.watch(merchantActiveOrdersProvider);
    final active = orders.value ?? const <StaffOrder>[];
    List<StaffOrder> only(Set<OrderStatus> statuses) => active.where((o) => statuses.contains(o.status)).toList();
    final fresh = only({OrderStatus.received});
    final preparing = only({OrderStatus.confirmed, OrderStatus.preparing});
    final ready = only({
      OrderStatus.ready,
      OrderStatus.courierAssigned,
      OrderStatus.onTheWay,
    });
    final stores = ref.watch(merchantStoresProvider).value ?? const <MerchantStore>[];
    final store = stores.firstOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 900 && MediaQuery.textScalerOf(context).scale(14) < 20;

    String tab(String label, int count) => count == 0 ? label : '$label ($count)';

    final actions = [
      if (store != null)
        PartnerHeroAction(
          icon: Icons.menu_book_rounded,
          tooltip: 'Productos',
          onPressed: () => context.pushNamed(
            MerchantProductsPage.name,
            pathParameters: {'storeId': store.id},
          ),
        ),
      const PartnerAccountButton(),
    ];

    Widget ordersTab(List<StaffOrder> list, String emptyTitle, String emptyMessage) => _OrdersTab(
      value: orders,
      orders: list,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
    );

    final tabs = wide
        ? const ['Comandas', 'Hoy']
        : [
            tab('Nuevas', fresh.length),
            tab('En fogón', preparing.length),
            tab('Listas', ready.length),
            'Hoy',
          ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: partnerStatusBar(context),
        body: SafeArea(
          top: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: wide
                    ? _RailHero(store: store, actions: actions)
                    : _KitchenHero(
                        store: store,
                        waiting: fresh.length,
                        actions: actions,
                        pill: stores.length == 1
                            ? _StoreSwitch(store: stores.single)
                            : ref.watch(merchantStoresProvider).isLoading && stores.isEmpty
                            ? const PartnerStatusPillSkeleton()
                            : null,
                      ),
              ),
              if (stores.length > 1) const SliverToBoxAdapter(child: _StoreSwitches()),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _OrderTabs(PartnerPillTabs(labels: tabs)),
                ),
              ),
            ],
            body: TabBarView(
              children: wide
                  ? [
                      _RailBoard(value: orders, fresh: fresh, cooking: preparing, ready: ready),
                      const _TodayTab(),
                    ]
                  : [
                      ordersTab(fresh, 'Sin comandas nuevas', 'Te avisaremos con una alarma cuando llegue la siguiente.'),
                      ordersTab(preparing, 'Nada en el fogón', 'Las comandas que aceptes aparecen aquí hasta que estén listas.'),
                      ordersTab(ready, 'Nada esperando repartidor', 'Aquí sigues la recogida y la entrega de lo que ya salió.'),
                      const _TodayTab(),
                    ],
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
    final user = ref.watch(authSessionProvider).value;
    final summary = ref.watch(merchantSummaryProvider).value;
    final parts = [
      if (summary != null) '${summary.deliveredCount + summary.activeCount} comandas · ${Formatters.money(summary.sales)} hoy',
      if (waiting > 0) '$waiting por responder' else if (summary != null) 'todo al día',
    ];
    return PartnerHero(
      eyebrow: 'CHASKI SOCIOS · COCINA',
      greeting: user == null ? null : '${partnerGreeting()}, ${user.firstName}',
      title: 'Tu cocina,',
      accent: 'al toque.',
      subtitle: summary == null ? null : parts.join(' · '),
      subtitleLoading: summary == null,
      imageUrl: store?.logoUrl,
      avatar: store == null || store!.logoUrl != null ? null : const _StoreMark(),
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

/// Portada en barra para el riel de la tablet.
class _RailHero extends ConsumerWidget {
  const _RailHero({required this.store, required this.actions});

  final MerchantStore? store;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ref.watch(merchantSummaryProvider).value;
    return Container(
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.hero),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 16, 16),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.surface, width: 3)),
                    child: AppNetworkImage(
                      url: store?.logoUrl,
                      width: 56,
                      height: 56,
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHASKI SOCIOS · ${(store?.name ?? 'Riel de comandas').toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer, letterSpacing: 1.4, fontWeight: FontWeight.w800),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Tu cocina, ',
                          children: [TextSpan(text: 'al toque.', style: TextStyle(color: scheme.primary))],
                        ),
                        style: TextStyle(fontFamily: AppTypography.display, fontSize: 28, fontWeight: FontWeight.w800, height: 1.05, color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
                if (summary == null) ...[
                  Container(
                    width: 110,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.button),
                    child: const Skeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 60, height: 9), SizedBox(height: 6), SkeletonBox(width: 80)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.button),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Comandas hoy', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                        Text(
                          '${summary.deliveredCount + summary.activeCount} · ${Formatters.money(summary.sales)}',
                          style: AppTypography.price(context, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (store != null)
                  SizedBox(width: 270, child: _StoreSwitch(store: store!, compact: true))
                else if (ref.watch(merchantStoresProvider).isLoading)
                  const SizedBox(width: 270, child: PartnerStatusPillSkeleton()),
                ...actions,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Las tres barras de la cocina: nuevas, en fogón y listas, con sus comandas colgadas.
class _RailBoard extends ConsumerWidget {
  const _RailBoard({required this.value, required this.fresh, required this.cooking, required this.ready});

  final AsyncValue<List<StaffOrder>> value;
  final List<StaffOrder> fresh;
  final List<StaffOrder> cooking;
  final List<StaffOrder> ready;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    Widget empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
    List<Widget> cards(List<StaffOrder> list) => [for (final o in list) MerchantOrderCard(key: ValueKey(o.id), order: o)];
    return RefreshIndicator(
      onRefresh: () => ref.refresh(merchantActiveOrdersProvider.future),
      child: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(merchantActiveOrdersProvider),
        loading: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, (title, dot)) in [('Nuevas', scheme.primary), ('En fogón', scheme.onSurface), ('Listas', AppColors.hierba)].indexed) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Expanded(
                        child: PartnerRail(
                          title: title,
                          dot: dot,
                          children: [ComandaSkeleton(withActions: i == 0)],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (_) => CustomScrollView(
          key: const PageStorageKey('rails'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PartnerRail(
                        title: 'Nuevas',
                        count: fresh.length,
                        dot: scheme.primary,
                        empty: empty('Sin comandas nuevas'),
                        children: cards(fresh),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: PartnerRail(
                        title: 'En fogón',
                        count: cooking.length,
                        dot: scheme.onSurface,
                        empty: empty('Nada en el fogón'),
                        children: cards(cooking),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: PartnerRail(
                        title: 'Listas',
                        count: ready.length,
                        dot: AppColors.hierba,
                        empty: empty('Nada esperando repartidor'),
                        children: cards(ready),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Cocina abierta · recibiendo": pausar deja de mostrar el negocio abierto.
class _StoreSwitch extends ConsumerStatefulWidget {
  const _StoreSwitch({required this.store, this.compact = false, this.named = false});

  final MerchantStore store;
  final bool compact;
  final bool named;

  @override
  ConsumerState<_StoreSwitch> createState() => _StoreSwitchState();
}

class _StoreSwitchState extends ConsumerState<_StoreSwitch> {
  var _saving = false;

  Future<void> _toggle(bool accepting) async {
    setState(() => _saving = true);
    final failure = await ref.read(merchantStoresProvider.notifier).setAccepting(widget.store, accepting: accepting);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final on = store.isAcceptingOrders;
    final title = widget.named
        ? store.name
        : !on
        ? 'Cocina en pausa'
        : widget.compact
        ? 'Cocina abierta'
        : 'Cocina abierta · recibiendo';
    final message = !store.isOpenNow
        ? 'Fuera de tu horario de atención'
        : !on
        ? 'Actívala cuando estés listo'
        : widget.compact
        ? 'Recibiendo comandas'
        : 'Los clientes ven tu negocio abierto';
    return PartnerStatusPill(
      title: title,
      message: message,
      value: on,
      busy: _saving,
      onChanged: _toggle,
    );
  }
}

/// Con varios negocios, una píldora por cada uno y el acceso a su carta.
class _StoreSwitches extends ConsumerWidget {
  const _StoreSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(merchantStoresProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
      child: AsyncValueView(
        value: stores,
        compactError: true,
        onRetry: () => ref.invalidate(merchantStoresProvider),
        loading: const PartnerStatusPillSkeleton(),
        data: (list) => Column(
          children: [
            for (final store in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Column(
                  children: [
                    _StoreSwitch(store: store, named: true),
                    TextButton.icon(
                      onPressed: () => context.pushNamed(
                        MerchantProductsPage.name,
                        pathParameters: {'storeId': store.id},
                      ),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text('Carta de ${store.name}'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderTabs extends SliverPersistentHeaderDelegate {
  _OrderTabs(this.tabs);

  final PartnerPillTabs tabs;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Align(alignment: Alignment.centerLeft, child: tabs),
  );

  @override
  bool shouldRebuild(_OrderTabs oldDelegate) => true;
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({
    required this.value,
    required this.orders,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final AsyncValue<List<StaffOrder>> value;
  final List<StaffOrder> orders;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(merchantActiveOrdersProvider.future),
      child: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(merchantActiveOrdersProvider),
        loading: _OrderListView(
          storageKey: '$emptyTitle-loading',
          itemCount: 2,
          itemBuilder: (_, i) => ComandaSkeleton(withActions: i == 0),
        ),
        isEmpty: (_) => orders.isEmpty,
        empty: _OrderListView(
          storageKey: emptyTitle,
          itemCount: 1,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: AppEmptyState(title: emptyTitle, message: emptyMessage),
          ),
        ),
        data: (_) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 && MediaQuery.textScalerOf(context).scale(14) < 20 ? 2 : 1;
            return _OrderListView(
              storageKey: emptyTitle,
              itemCount: (orders.length / columns).ceil(),
              itemBuilder: (_, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: i * columns + column < orders.length
                          ? MerchantOrderCard(
                              key: ValueKey(orders[i * columns + column].id),
                              order: orders[i * columns + column],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reserva el espacio ocupado por las pestañas cuando quedan fijas arriba.
class _OrderListView extends StatelessWidget {
  const _OrderListView({required this.storageKey, required this.itemCount, required this.itemBuilder});

  final String storageKey;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: PageStorageKey(storageKey),
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
        sliver: SliverList.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        ),
      ),
    ],
  );
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(merchantTodayOrdersProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(merchantSummaryProvider)
          ..invalidate(merchantTodayOrdersProvider);
        await ref.read(merchantTodayOrdersProvider.future);
      },
      child: AsyncValueView(
        value: today,
        onRetry: () => ref.invalidate(merchantTodayOrdersProvider),
        loading: _OrderListView(
          storageKey: 'today-loading',
          itemCount: 4,
          itemBuilder: (_, i) => i == 0 ? const _TodayMetricsSkeleton() : const _TodayRowSkeleton(),
        ),
        data: (orders) => _OrderListView(
          storageKey: 'today',
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TodayMetrics(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Pedidos de hoy', style: theme.textTheme.titleLarge),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.md),
                      child: Text('Todavía no hay pedidos hoy.'),
                    ),
                ],
              );
            }
            final order = orders[index - 1];
            return PartnerSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaffOrderHeader(order: order),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        order.customerName,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        Formatters.money(order.order.subtotal),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TodayMetrics extends ConsumerWidget {
  const _TodayMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AsyncValueView(
      value: ref.watch(merchantSummaryProvider),
      compactError: true,
      onRetry: () => ref.invalidate(merchantSummaryProvider),
      loading: const _TodayMetricsSkeleton(),
      data: (summary) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: AppRadius.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendido hoy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              Formatters.money(summary.sales),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  '${summary.deliveredCount} entregados',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${summary.cancelledCount} cancelados',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Vendido hoy" mientras cargan los números: la misma tarjeta tostada.
class _TodayMetricsSkeleton extends StatelessWidget {
  const _TodayMetricsSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: AppRadius.card),
    child: const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 90),
          SizedBox(height: 10),
          SkeletonBox(width: 150, height: 34),
          SizedBox(height: AppSpacing.md),
          Row(children: [SkeletonBox(width: 90), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 90)]),
        ],
      ),
    ),
  );
}

class _TodayRowSkeleton extends StatelessWidget {
  const _TodayRowSkeleton();

  @override
  Widget build(BuildContext context) => const PartnerSurface(
    child: Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [SkeletonBox(width: 80, height: 22), SizedBox(width: 8), SkeletonBox(width: 70, height: 20)]),
          SizedBox(height: 8),
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: 10),
          Row(children: [SkeletonBox(width: 110), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 60)]),
        ],
      ),
    ),
  );
}
