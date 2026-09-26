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
    final ready = only({OrderStatus.ready, OrderStatus.courierAssigned, OrderStatus.onTheWay});
    final store = ref.watch(merchantStoresProvider).value?.firstOrNull;

    String tab(String label, int count) => count == 0 ? label : '$label ($count)';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(store?.name ?? 'Tu negocio', overflow: TextOverflow.ellipsis),
          actions: [
            if (store != null)
              IconButton(
                tooltip: 'Productos',
                icon: const Icon(Icons.inventory_2_outlined),
                onPressed: () => context.pushNamed(MerchantProductsPage.name, pathParameters: {'storeId': store.id}),
              ),
            const PartnerAccountButton(),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: tab('Nuevos', fresh.length)),
              Tab(text: tab('Preparando', preparing.length)),
              Tab(text: tab('Listos', ready.length)),
              const Tab(text: 'Hoy'),
            ],
          ),
        ),
        body: Column(
          children: [
            const _StoreSwitches(),
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersTab(
                    value: orders,
                    orders: fresh,
                    emptyTitle: 'Sin pedidos nuevos',
                    emptyMessage: 'Cuando entre uno, sonará una alarma hasta que lo aceptes o rechaces.',
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
                    emptyMessage: 'Los pedidos listos quedan aquí hasta que el repartidor los recoge.',
                  ),
                  const _TodayTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Recibiendo pedidos" por negocio. Pausar deja de mostrarlo abierto.
class _StoreSwitches extends ConsumerWidget {
  const _StoreSwitches();

  Future<void> _toggle(BuildContext context, WidgetRef ref, MerchantStore store, bool accepting) async {
    final failure = await ref.read(merchantStoresProvider.notifier).setAccepting(store, accepting: accepting);
    if (failure != null && context.mounted) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stores = ref.watch(merchantStoresProvider).value ?? const <MerchantStore>[];
    return Column(
      children: [
        for (final store in stores)
          ListTile(
            contentPadding: AppSpacing.screen,
            title: Text(stores.length > 1 ? store.name : 'Recibiendo pedidos'),
            subtitle: Text(
              !store.isOpenNow
                  ? 'Fuera de tu horario de atención'
                  : store.isAcceptingOrders
                  ? 'Los clientes te ven abierto'
                  : 'En pausa: los clientes te ven cerrado',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Switch(
              value: store.isAcceptingOrders,
              onChanged: (value) => _toggle(context, ref, store, value),
            ),
          ),
      ],
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.value, required this.orders, required this.emptyTitle, required this.emptyMessage});

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
        empty: ListView(
          children: [
            const SizedBox(height: AppSpacing.xl),
            AppEmptyState(title: emptyTitle, message: emptyMessage),
          ],
        ),
        data: (_) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => MerchantOrderCard(key: ValueKey(orders[i].id), order: orders[i]),
        ),
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(merchantSummaryProvider);
    final today = ref.watch(merchantTodayOrdersProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(merchantSummaryProvider)
          ..invalidate(merchantTodayOrdersProvider);
        await ref.read(merchantTodayOrdersProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
        children: [
          if (summary.value case final s?)
            Row(
              children: [
                Expanded(child: _Stat(label: 'Vendido', value: Formatters.money(s.sales))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _Stat(label: 'Entregados', value: '${s.deliveredCount}')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _Stat(label: 'Cancelados', value: '${s.cancelledCount}')),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Pedidos de hoy', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ...switch (today) {
            AsyncData(:final value) when value.isEmpty => [
              Text('Todavía no hay pedidos hoy.', style: theme.textTheme.bodyMedium),
            ],
            AsyncData(:final value) => [
              for (final o in value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${o.order.code} · ${o.customerName}'),
                  subtitle: Text('${o.status.staffLabel} · ${Formatters.clock(o.order.placedAt)}'),
                  trailing: Text(Formatters.money(o.order.subtotal), style: theme.textTheme.titleSmall),
                ),
            ],
            AsyncError(:final error) => [Text(error.toString())],
            _ => [const Center(child: CircularProgressIndicator())],
          },
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(child: Text(value, style: theme.textTheme.titleLarge)),
        ],
      ),
    );
  }
}
