import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/presentation/pages/active_delivery_page.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inicio del modo Repartidor: conectarse, el pedido en curso y los pedidos
/// listos para tomar.
class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  static const name = 'courierHome';

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> {
  late final OrderAlarm _alarm;

  /// Pedidos disponibles que ya vio: suena solo cuando aparece uno nuevo.
  final Set<String> _seen = {};

  @override
  void initState() {
    super.initState();
    _alarm = ref.read(orderAlarmProvider);
  }

  @override
  void dispose() {
    _alarm
      ..silence().ignore()
      ..keepAwake(on: false).ignore();
    super.dispose();
  }

  Future<void> _setOnline(bool online) async {
    final failure = await ref.read(courierMeProvider.notifier).setOnline(online: online);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
    } else {
      AppToast.show(context, online ? 'Conectado. Te avisamos cuando haya pedidos.' : 'Desconectado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(courierMeProvider, (_, next) {
        final online = next.value?.isOnline ?? false;
        _alarm.keepAwake(on: online).ignore();
      })
      ..listen(courierAvailableOrdersProvider, (_, next) {
        final orders = next.value;
        if (orders == null) return;
        final fresh = orders.where((o) => !_seen.contains(o.id)).isNotEmpty;
        _seen.addAll(orders.map((o) => o.id));
        if (orders.isEmpty) {
          _alarm.silence().ignore();
        } else if (fresh) {
          _alarm.ring().ignore();
        }
      });

    final theme = Theme.of(context);
    final me = ref.watch(courierMeProvider);
    final active = ref.watch(courierActiveDeliveryProvider).value;
    final profile = me.value;
    final online = profile?.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Reparto'), actions: const [PartnerAccountButton()]),
      body: AsyncValueView(
        value: me,
        onRetry: () => ref.invalidate(courierMeProvider),
        loading: const Center(child: CircularProgressIndicator()),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(courierMeProvider)
              ..invalidate(courierActiveDeliveryProvider)
              ..invalidate(courierAvailableOrdersProvider)
              ..invalidate(courierSummaryProvider);
            await ref.read(courierMeProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              SwitchListTile(
                contentPadding: AppSpacing.screen,
                title: Text(online ? 'Conectado' : 'Desconectado', style: theme.textTheme.titleMedium),
                subtitle: Text(
                  switch (profile.availability) {
                    CourierAvailability.offline => 'Conéctate para ver pedidos listos en tu ciudad.',
                    CourierAvailability.available => 'Recibes pedidos · ${profile.vehicleLabel}',
                    CourierAvailability.busy => 'Llevando un pedido',
                  },
                ),
                value: online,
                onChanged: _setOnline,
              ),
              if (active != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
                  child: _ActiveDeliveryBanner(order: active),
                ),
              if (online && active == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xs),
                  child: Text('Listos para recoger', style: theme.textTheme.titleMedium),
                ),
                const _AvailableOrders(),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                child: _TodaySummary(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDeliveryBanner extends StatelessWidget {
  const _ActiveDeliveryBanner({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickingUp = order.status == OrderStatus.courierAssigned;
    return AppCard(
      variant: AppCardVariant.raised,
      onTap: () => context.pushNamed(ActiveDeliveryPage.name, pathParameters: {'orderId': order.id}),
      child: Row(
        children: [
          Icon(pickingUp ? Icons.storefront_outlined : Icons.delivery_dining, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickingUp ? 'Recoge en ${order.order.store.name}' : 'Entrega a ${order.customerName}',
                  style: theme.textTheme.titleMedium,
                ),
                Text('${order.order.code} · cobrar ${Formatters.money(order.order.total)}'),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _AvailableOrders extends ConsumerStatefulWidget {
  const _AvailableOrders();

  @override
  ConsumerState<_AvailableOrders> createState() => _AvailableOrdersState();
}

class _AvailableOrdersState extends ConsumerState<_AvailableOrders> {
  String? _taking;

  Future<void> _accept(StaffOrder order) async {
    setState(() => _taking = order.id);
    final failure = await ref.read(courierActionsProvider.notifier).accept(order.id);
    if (!mounted) return;
    setState(() => _taking = null);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
      return;
    }
    await context.pushNamed(ActiveDeliveryPage.name, pathParameters: {'orderId': order.id});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(courierAvailableOrdersProvider);
    return AsyncValueView(
      value: orders,
      compactError: true,
      onRetry: () => ref.invalidate(courierAvailableOrdersProvider),
      loading: const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator())),
      isEmpty: (list) => list.isEmpty,
      empty: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: AppEmptyState(
          title: 'Nada por ahora',
          message: 'Cuando un negocio marque un pedido listo, sonará y aparecerá aquí.',
        ),
      ),
      data: (list) => Column(
        children: [
          for (final order in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
              child: AppCard(
                variant: AppCardVariant.raised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaffOrderHeader(order: order),
                    const SizedBox(height: AppSpacing.xs),
                    Text(order.order.store.name, style: theme.textTheme.titleMedium),
                    Text(order.pickup.address, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Hasta ${order.order.addressStreet} · ${Formatters.distance(order.distanceMeters / 1000)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(child: Text('Envío ${Formatters.money(order.order.deliveryFee)}')),
                        Text('Cobrar ${Formatters.money(order.order.total)}', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Tomar pedido',
                      loading: _taking == order.id,
                      onPressed: _taking == null ? () => _accept(order) : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodaySummary extends ConsumerWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(courierSummaryProvider).value;
    if (summary == null) return const SizedBox.shrink();
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoy', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${summary.deliveredCount} ${summary.deliveredCount == 1 ? 'entrega' : 'entregas'} · '
            'cobraste ${Formatters.money(summary.total)}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Efectivo ${Formatters.money(summary.cash)} · Yape ${Formatters.money(summary.yape)} · '
            'Plin ${Formatters.money(summary.plin)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}
