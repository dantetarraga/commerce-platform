import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/presentation/pages/active_delivery_page.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La disponibilidad, la siguiente entrega y el cierre de la jornada.
class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  static const name = 'courierHome';

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> {
  late final OrderAlarm _alarm;
  final Set<String> _seen = {};
  var _changingAvailability = false;

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
    setState(() => _changingAvailability = true);
    final failure = await ref.read(courierMeProvider.notifier).setOnline(online: online);
    if (!mounted) return;
    setState(() => _changingAvailability = false);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(
        courierMeProvider,
        (_, next) => _alarm.keepAwake(on: next.value?.isOnline ?? false).ignore(),
      )
      ..listen(courierAvailableOrdersProvider, (_, next) {
        final orders = next.value;
        if (orders == null) return;
        final fresh = orders.any((o) => !_seen.contains(o.id));
        _seen.addAll(orders.map((o) => o.id));
        if (orders.isEmpty) {
          _alarm.silence().ignore();
        } else if (fresh) {
          _alarm.ring().ignore();
        }
      });

    final me = ref.watch(courierMeProvider);
    final delivery = ref.watch(courierActiveDeliveryProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const PartnerAppTitle(title: 'Reparto'),
        actions: const [PartnerAccountButton()],
      ),
      body: SafeArea(
        top: false,
        child: PartnerContent(
          maxWidth: 760,
          child: AsyncValueView(
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xs,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PartnerSectionHeading(
                            title: 'Hola, ${profile.name.split(' ').first}',
                            subtitle: 'Cada entrega empieza contigo.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PartnerAvailability(
                            title: profile.isOnline ? 'Conectado' : 'Desconectado',
                            message: switch (profile.availability) {
                              CourierAvailability.offline => 'Actívate cuando estés listo para repartir.',
                              CourierAvailability.available => 'Recibes pedidos · ${profile.vehicleLabel}',
                              CourierAvailability.busy => 'Tienes una entrega en curso',
                            },
                            icon: profile.isOnline ? Icons.delivery_dining_rounded : Icons.pause_circle_outline_rounded,
                            value: profile.isOnline,
                            busy: _changingAvailability,
                            onChanged: _setOnline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (delivery.value case final active?)
                    SliverPadding(
                      padding: AppSpacing.screen,
                      sliver: SliverToBoxAdapter(
                        child: _ActiveDeliveryBanner(order: active),
                      ),
                    )
                  else if (delivery.hasError || !delivery.hasValue)
                    SliverToBoxAdapter(
                      child: AsyncValueView(
                        value: delivery,
                        compactError: true,
                        onRetry: () => ref.invalidate(courierActiveDeliveryProvider),
                        loading: const LinearProgressIndicator(),
                        data: (_) => const SizedBox.shrink(),
                      ),
                    )
                  else if (profile.isOnline) ...[
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        0,
                        AppSpacing.gutter,
                        AppSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: PartnerSectionHeading(
                          title: 'Listos para recoger',
                          subtitle: 'Elige tu próximo recorrido.',
                        ),
                      ),
                    ),
                    const _AvailableOrders(),
                  ] else
                    SliverPadding(
                      padding: AppSpacing.screen,
                      sliver: SliverToBoxAdapter(
                        child: PartnerSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.route_rounded,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tu próxima ruta empieza aquí',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                'Al conectarte verás dónde recoger, dónde entregar y cuánto cobrar antes de tomar un pedido.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xl,
                      AppSpacing.gutter,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(child: _TodaySummary()),
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

class _ActiveDeliveryBanner extends StatelessWidget {
  const _ActiveDeliveryBanner({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickingUp = order.status == OrderStatus.courierAssigned;
    return PartnerSurface(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TU ENTREGA EN CURSO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pickingUp ? 'Recoge en ${order.order.store.name}' : 'Entrega a ${order.customerName}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(pickingUp ? order.pickup.address : order.order.addressStreet),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${order.order.code} · Cobrar ${Formatters.money(order.order.total)}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Continuar entrega',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.pushNamed(
              ActiveDeliveryPage.name,
              pathParameters: {'orderId': order.id},
            ),
          ),
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
    await context.pushNamed(
      ActiveDeliveryPage.name,
      pathParameters: {'orderId': order.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(courierAvailableOrdersProvider);
    final list = orders.value;
    if (list == null || list.isEmpty) {
      return SliverToBoxAdapter(
        child: AsyncValueView(
          value: orders,
          compactError: true,
          onRetry: () => ref.invalidate(courierAvailableOrdersProvider),
          loading: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          data: (_) => const AppEmptyState(
            title: 'Nada por ahora',
            message: 'Te avisaremos cuando un negocio tenga un pedido listo.',
          ),
        ),
      );
    }
    return SliverPadding(
      padding: AppSpacing.screen,
      sliver: SliverList.separated(
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final order = list[index];
          return PartnerSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaffOrderHeader(order: order),
                const SizedBox(height: AppSpacing.md),
                _RouteStop(
                  icon: Icons.storefront_rounded,
                  label: 'RECOGER',
                  title: order.order.store.name,
                  address: order.pickup.address,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 18,
                      child: VerticalDivider(color: theme.colorScheme.outline),
                    ),
                  ),
                ),
                _RouteStop(
                  icon: Icons.location_on_outlined,
                  label: 'ENTREGAR',
                  title: order.order.addressStreet,
                  address: Formatters.distance(order.distanceMeters / 1000),
                ),
                const Divider(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PartnerMetric(
                      label: 'Costo de envío',
                      value: Formatters.money(order.order.deliveryFee),
                    ),
                    PartnerMetric(
                      label: 'Cobrar al cliente',
                      value: Formatters.money(order.order.total),
                      emphasized: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Tomar pedido',
                  loading: _taking == order.id,
                  onPressed: _taking == null ? () => _accept(order) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.label,
    required this.title,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String title;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodaySummary extends ConsumerWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AsyncValueView(
      value: ref.watch(courierSummaryProvider),
      compactError: true,
      onRetry: () => ref.invalidate(courierSummaryProvider),
      loading: const LinearProgressIndicator(),
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerSectionHeading(
            title: 'Tu jornada de hoy',
            subtitle:
                '${summary.deliveredCount} ${summary.deliveredCount == 1 ? 'entrega completada' : 'entregas completadas'}',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total cobrado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  Formatters.money(summary.total),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              PartnerMetric(
                label: 'Efectivo',
                value: Formatters.money(summary.cash),
              ),
              PartnerMetric(
                label: 'Yape',
                value: Formatters.money(summary.yape),
              ),
              PartnerMetric(
                label: 'Plin',
                value: Formatters.money(summary.plin),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
