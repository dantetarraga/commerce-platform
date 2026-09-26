import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/pages/merchant_products_page.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_order_card.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
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
    final store = ref.watch(merchantStoresProvider).value?.firstOrNull;

    String tab(String label, int count) => count == 0 ? label : '$label ($count)';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: PartnerAppTitle(title: store?.name ?? 'Tu negocio'),
          actions: [
            if (store != null)
              IconButton(
                tooltip: 'Productos',
                icon: const Icon(Icons.inventory_2_outlined),
                onPressed: () => context.pushNamed(
                  MerchantProductsPage.name,
                  pathParameters: {'storeId': store.id},
                ),
              ),
            const PartnerAccountButton(),
          ],
        ),
        body: SafeArea(
          top: false,
          child: PartnerContent(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const SliverToBoxAdapter(child: _StoreSwitches()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: PartnerSectionHeading(
                      title: 'Tu operación',
                      subtitle: !orders.hasValue
                          ? orders.hasError
                                ? 'No pudimos actualizar tus pedidos.'
                                : 'Consultando tus pedidos…'
                          : fresh.isEmpty
                          ? 'Todo al día. Aquí sigue cada pedido.'
                          : '${fresh.length} ${fresh.length == 1 ? 'pedido necesita' : 'pedidos necesitan'} tu respuesta.',
                    ),
                  ),
                ),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _OrderTabs(
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: AppSpacing.screen,
                        labelStyle: Theme.of(context).textTheme.labelLarge,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: tab('Nuevos', fresh.length)),
                          Tab(text: tab('Preparando', preparing.length)),
                          Tab(text: tab('Listos', ready.length)),
                          const Tab(text: 'Hoy'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OrdersTab(
                    value: orders,
                    orders: fresh,
                    emptyTitle: 'Sin pedidos nuevos',
                    emptyMessage: 'Te avisaremos con una alarma cuando llegue el siguiente.',
                  ),
                  _OrdersTab(
                    value: orders,
                    orders: preparing,
                    emptyTitle: 'Nada en preparación',
                    emptyMessage: 'Los pedidos que aceptes aparecen aquí hasta que los marques listos.',
                  ),
                  _OrdersTab(
                    value: orders,
                    orders: ready,
                    emptyTitle: 'Nada esperando repartidor',
                    emptyMessage: 'Aquí seguirás la recogida y la entrega de los pedidos listos.',
                  ),
                  const _TodayTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Recibiendo pedidos" por negocio. Pausar deja de mostrarlo abierto.
class _StoreSwitches extends ConsumerStatefulWidget {
  const _StoreSwitches();

  @override
  ConsumerState<_StoreSwitches> createState() => _StoreSwitchesState();
}

class _StoreSwitchesState extends ConsumerState<_StoreSwitches> {
  final Set<String> _saving = {};

  Future<void> _toggle(MerchantStore store, bool accepting) async {
    setState(() => _saving.add(store.id));
    final failure = await ref.read(merchantStoresProvider.notifier).setAccepting(store, accepting: accepting);
    if (!mounted) return;
    setState(() => _saving.remove(store.id));
    if (failure != null) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(merchantStoresProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        0,
      ),
      child: AsyncValueView(
        value: stores,
        compactError: true,
        onRetry: () => ref.invalidate(merchantStoresProvider),
        loading: const LinearProgressIndicator(),
        data: (list) => Column(
          children: [
            for (final store in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Column(
                  children: [
                    PartnerAvailability(
                      title: list.length > 1
                          ? store.name
                          : store.isAcceptingOrders
                          ? 'Recibiendo pedidos'
                          : 'Pedidos en pausa',
                      message: !store.isOpenNow
                          ? 'Fuera de tu horario de atención'
                          : store.isAcceptingOrders
                          ? 'Tu tienda está abierta para los clientes'
                          : 'Activa tu tienda cuando estés listo',
                      icon: Icons.storefront_rounded,
                      value: store.isAcceptingOrders,
                      busy: _saving.contains(store.id),
                      onChanged: (value) => _toggle(store, value),
                    ),
                    if (list.length > 1)
                      TextButton.icon(
                        onPressed: () => context.pushNamed(
                          MerchantProductsPage.name,
                          pathParameters: {'storeId': store.id},
                        ),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: Text('Productos de ${store.name}'),
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

  final TabBar tabs;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

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
        loading: const Center(child: CircularProgressIndicator()),
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
        loading: const Center(child: CircularProgressIndicator()),
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
      loading: const LinearProgressIndicator(),
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
