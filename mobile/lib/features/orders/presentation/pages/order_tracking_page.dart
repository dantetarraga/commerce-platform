import 'package:apamuy/core/time/clock_provider.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/domain/order_insights.dart';
import 'package:apamuy/features/orders/presentation/order_status_labels.dart';
import 'package:apamuy/features/orders/presentation/pages/order_help_page.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
import 'package:apamuy/features/orders/presentation/widgets/courier_card.dart';
import 'package:apamuy/features/orders/presentation/widgets/order_stage_track.dart';
import 'package:apamuy/features/orders/presentation/widgets/order_ticket.dart';
import 'package:apamuy/features/orders/presentation/widgets/rating_sheet.dart';
import 'package:apamuy/features/orders/presentation/widgets/route_map.dart';
import 'package:apamuy/features/orders/presentation/widgets/tracking_skeleton.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pedido en curso: mapa arriba y una hoja con cuánto falta, cada paso con su
/// hora y quién lo lleva.
class OrderTrackingPage extends ConsumerStatefulWidget {
  const OrderTrackingPage({required this.orderId, super.key});

  static const name = 'order-tracking';

  final String orderId;

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  var _ratingOffered = false;

  void _onStatusChange(Order? previous, Order next) {
    if (previous == null || previous.status == next.status) return;
    HapticFeedback.mediumImpact().ignore();
    if (next.status == OrderStatus.delivered && next.rating == null && !_ratingOffered) {
      _ratingOffered = true;
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) showRatingSheet(context, next).ignore();
      }).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderWatchProvider(widget.orderId), (prev, next) {
      if (next.value case final order?) _onStatusChange(prev?.value, order);
    });
    final order = ref.watch(orderWatchProvider(widget.orderId));
    return switch (order) {
      AsyncValue(:final value?) => _Tracking(order: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Tu pedido')),
        body: AppEmptyState.fromError(error, onRetry: () => ref.invalidate(orderWatchProvider(widget.orderId))),
      ),
      _ => const TrackingSkeleton(),
    };
  }
}

/// La hora para lo que avanza solo (minutos, repartidor en el mapa). Con el
/// pedido terminado no se escucha el reloj, así deja de latir.
DateTime _liveNow(WidgetRef ref, Order order) =>
    order.status.isFinal ? DateTime.now() : ref.watch(clockProvider).value ?? DateTime.now();

class _Tracking extends StatelessWidget {
  const _Tracking({required this.order});

  final Order order;

  void _openHelp(BuildContext context) => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': order.id});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapHeight = MediaQuery.sizeOf(context).height * 0.56;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: mapHeight, child: _TrackingMap(order: order)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  AppCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    elevated: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  AppCircleButton(
                    icon: Icons.help_outline_rounded,
                    tooltip: 'Ayuda con tu pedido',
                    elevated: true,
                    onPressed: () => _openHelp(context),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            minChildSize: 0.50,
            maxChildSize: 0.94,
            builder: (context, controller) => DecoratedBox(
              decoration: BoxDecoration(borderRadius: AppRadius.sheet, boxShadow: AppShadows.raised(theme.brightness)),
              // Material propio: el ExpansionTile del detalle pinta su tinta aquí.
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.sheet,
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: theme.colorScheme.outline, borderRadius: const BorderRadius.all(AppRadius.pill)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EtaHeader(order: order),
                    if (order.status != OrderStatus.cancelled) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Track(order: order),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _Headline(order: order)),
                        TextButton(
                          onPressed: () => _showHistory(context, order),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.only(left: AppSpacing.sm)),
                          child: const Text('Historial ›'),
                        ),
                      ],
                    ),
                    if (order.courier case final courier?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      CourierCard(courier: courier),
                    ],
                    if (order.status == OrderStatus.delivered) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: order.rating == null ? 'Calificar pedido' : 'Gracias por calificar',
                        onPressed: order.rating == null ? () => showRatingSheet(context, order) : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OrderTicket(order: order),
                    const SizedBox(height: AppSpacing.sm),
                    AppGroupedRow.link(
                      icon: Icons.help_outline_rounded,
                      title: '¿Algún problema con tu pedido?',
                      onTap: () => _openHelp(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMap extends ConsumerWidget {
  const _TrackingMap({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RouteMap(
    progress: order.routeProgress(_liveNow(ref, order)),
    storeLabel: order.store.name,
    destinationLabel: order.addressTitle,
    showCourier: order.courier != null && order.reached(OrderStatus.courierAssigned),
    store: order.store.location,
    destination: order.destination,
    courier: order.status == OrderStatus.onTheWay ? order.courier?.position?.coordinates : null,
  );
}

/// El riel de íconos; en camino, la línea hacia la casa avanza con el repartidor.
class _Track extends ConsumerWidget {
  const _Track({required this.order});

  final Order order;

  /// Tramo del riel (no se usa con el pedido cancelado).
  static int _stageOf(OrderStatus status) => switch (status) {
    OrderStatus.received || OrderStatus.confirmed || OrderStatus.cancelled => 0,
    OrderStatus.preparing || OrderStatus.ready => 1,
    OrderStatus.courierAssigned || OrderStatus.onTheWay => 2,
    OrderStatus.delivered => 3,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderStageTrack(
      current: _stageOf(order.status),
      // En camino, la línea hacia la casa avanza con el repartidor.
      travel: order.status == OrderStatus.onTheWay ? order.routeProgress(_liveNow(ref, order)) : null,
      stages: [
        // El primero dice "Recibido" hasta que el negocio acepta.
        (label: order.status == OrderStatus.received ? 'Recibido' : 'Confirmado', icon: Icons.receipt_long_rounded),
        (label: 'Preparando', icon: Icons.soup_kitchen_rounded),
        (label: 'En camino', icon: Icons.two_wheeler_rounded),
        (label: 'Entregado', icon: Icons.home_rounded),
      ],
    );
  }
}

/// Cuánto falta en grande, a qué hora llega y la etiqueta viva.
class _EtaHeader extends ConsumerWidget {
  const _EtaHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apamuy = context.apamuy;
    final minutes = order.minutesLeft(_liveNow(ref, order));
    final deliveredAt = order.timeOf(OrderStatus.delivered);
    final eta = order.estimatedArrival;
    final (String caption, String big) = switch (order.status) {
      OrderStatus.delivered => ('Llegó a las', deliveredAt == null ? '¡Listo!' : Formatters.clock(deliveredAt)),
      OrderStatus.cancelled => ('Tu pedido', 'Cancelado'),
      _ when minutes != null => (eta == null ? 'Llega en' : 'Llega a las ${Formatters.clock(eta)}', '$minutes min'),
      _ when eta != null => ('Llega a las', Formatters.clock(eta)),
      _ => ('Llega en', 'Calculando…'),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(big, style: theme.textTheme.displaySmall?.copyWith(fontFeatures: AppTypography.tabularFigures, height: 1.1)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AppLiveTag(
            label: order.status.tag,
            live: !order.status.isFinal,
            color: switch (order.status) {
              OrderStatus.delivered => apamuy.success,
              OrderStatus.cancelled => apamuy.danger,
              _ => null,
            },
          ),
        ),
      ],
    );
  }
}

/// Qué está pasando, con nombre propio. Al cambiar de estado el texto anterior se
/// va de golpe y entra el nuevo, para que no se encimen.
class _Headline extends StatelessWidget {
  const _Headline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
        switchInCurve: AppMotion.arrive,
        layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: SizedBox(
          key: ValueKey(order.status),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.headline, style: theme.textTheme.titleMedium),
              Text(order.detail, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showHistory(BuildContext context, Order order) => showAppBottomSheet<void>(
  context,
  title: 'Historial del pedido',
  subtitle: '${order.code} · ${order.store.name}',
  builder: (_) => _History(orderId: order.id),
).ignore();

/// Lo que ya pasó, del más reciente al más antiguo, como renglones de boleta.
/// Escucha el pedido: si avanza con la hoja abierta, se imprime el renglón nuevo.
class _History extends ConsumerWidget {
  const _History({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderWatchProvider(orderId)).value;
    if (order == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final events = [...order.events]..sort((a, b) => b.at.compareTo(a.at));
    final time = theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppTypography.tabularFigures);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
            child: Column(
              children: [
                for (final (i, e) in events.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: LeaderRow(
                      label: Text(
                        order.stepTitle(e.status),
                        style: i == 0 && !order.status.isFinal ? theme.textTheme.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700) : theme.textTheme.bodyMedium,
                      ),
                      value: Text(Formatters.clock(e.at), style: time),
                    ),
                  ),
              ],
            ),
          ),
          const TicketEdge(top: false),
        ],
      ),
    );
  }
}
