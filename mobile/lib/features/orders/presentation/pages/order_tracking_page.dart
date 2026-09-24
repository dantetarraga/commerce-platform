import 'dart:async';

import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/pages/order_help_page.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/features/orders/presentation/widgets/order_bits.dart';
import 'package:chaski/features/orders/presentation/widgets/rating_sheet.dart';
import 'package:chaski/features/orders/presentation/widgets/route_map.dart';
import 'package:chaski/shared/design_system/design_system.dart';
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
  Timer? _clock;
  var _now = DateTime.now();
  var _ratingOffered = false;

  @override
  void initState() {
    super.initState();
    // Refresca los minutos restantes y el avance del repartidor.
    _clock = Timer.periodic(const Duration(seconds: 15), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _onStatusChange(Order? previous, Order next) {
    if (previous == null || previous.status == next.status) return;
    HapticFeedback.mediumImpact().ignore();
    // Al entregarse: una sola celebración y la calificación a mano.
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
      AsyncValue(:final value?) => _Tracking(order: value, now: _now),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Tu pedido')),
        body: orderLoadError(error, what: 'tu pedido', onRetry: () => ref.invalidate(orderWatchProvider(widget.orderId))),
      ),
      _ => const _TrackingSkeleton(),
    };
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.order, required this.now});

  final Order order;
  final DateTime now;

  /// Avance estimado del repartidor entre la salida y la llegada.
  double get _routeProgress {
    final left = order.timeOf(OrderStatus.onTheWay);
    final eta = order.estimatedArrival;
    if (order.status == OrderStatus.delivered) return 1;
    if (!order.reached(OrderStatus.onTheWay)) return 0;
    if (left == null || eta == null) return 0.05;
    final total = eta.difference(left).inSeconds;
    if (total <= 0) return 0.9;
    return (now.difference(left).inSeconds / total).clamp(0.05, 0.95);
  }

  void _openHelp(BuildContext context) => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': order.id});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;
    final mapHeight = height * 0.5;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight,
            child: RouteMap(
              progress: _routeProgress,
              showCourier: order.courier != null && order.reached(OrderStatus.courierAssigned),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  CircleAction(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    elevated: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  CircleAction(
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
            initialChildSize: 0.56,
            minChildSize: 0.56,
            maxChildSize: 0.94,
            builder: (context, controller) => DecoratedBox(
              decoration: BoxDecoration(borderRadius: AppRadius.sheet, boxShadow: AppShadows.raised(theme.brightness)),
              // Material propio: las filas (ExpansionTile) pintan su tinta aquí.
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
                    _EtaHeader(order: order, now: now),
                    const SizedBox(height: AppSpacing.lg),
                    AppQuipu(dense: true, steps: _steps()),
                    if (order.courier case final courier?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _CourierCard(courier: courier),
                    ],
                    if (order.status == OrderStatus.delivered) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: order.rating == null ? 'Calificar pedido' : 'Gracias por calificar',
                        onPressed: order.rating == null ? () => showRatingSheet(context, order) : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _HelpRow(label: '¿Algún problema con tu pedido?', onTap: () => _openHelp(context)),
                    const SizedBox(height: AppSpacing.xs),
                    _Summary(order: order),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<QuipuStep> _steps() {
    final owner = order.store.ownerName ?? order.store.name;
    final rider = order.courier?.firstName;
    String title(OrderStatus s) => switch (s) {
      OrderStatus.received => 'Recibido',
      OrderStatus.confirmed => 'Confirmado por $owner',
      OrderStatus.preparing => order.reached(OrderStatus.ready) ? 'Preparado por $owner' : '$owner lo está preparando',
      OrderStatus.ready => 'Listo para salir',
      OrderStatus.courierAssigned => rider == null ? 'Repartidor asignado' : '$rider lo recogió',
      OrderStatus.onTheWay => rider == null ? 'En camino' : '$rider va en camino',
      OrderStatus.delivered => 'Entregado',
      OrderStatus.cancelled => 'Cancelado',
    };
    final cancelled = order.status == OrderStatus.cancelled;
    return [
      for (final s in OrderStatus.timeline)
        if (!cancelled || order.timeOf(s) != null)
          QuipuStep(
            title: title(s),
            trailing: switch (order.timeOf(s)) {
              final at? => clock12(at),
              // Solo la entrega tiene hora estimada.
              null when s == OrderStatus.delivered && order.estimatedArrival != null && order.isActive =>
                '~${clock12(order.estimatedArrival!)}',
              null => null,
            },
            knot: order.status == s && !s.isFinal
                ? QuipuKnot.current
                : order.reached(s)
                ? QuipuKnot.done
                : QuipuKnot.todo,
          ),
      if (cancelled) QuipuStep(title: 'Cancelado', trailing: _clockOf(order.timeOf(OrderStatus.cancelled)), knot: QuipuKnot.done),
    ];
  }
}

String? _clockOf(DateTime? at) => at == null ? null : clock12(at);

/// "Llega en" + ETA grande + etiqueta viva; el mensaje humano cambia con el estado.
class _EtaHeader extends StatelessWidget {
  const _EtaHeader({required this.order, required this.now});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    final minutes = order.minutesLeft(now);
    final delivered = order.status == OrderStatus.delivered;
    final cancelled = order.status == OrderStatus.cancelled;
    final (String caption, String big) = switch (order.status) {
      OrderStatus.delivered => ('Llegó a las', _clockOf(order.timeOf(OrderStatus.delivered)) ?? '¡Listo!'),
      OrderStatus.cancelled => ('Tu pedido', 'Cancelado'),
      _ when minutes != null => ('Llega en', '$minutes min'),
      _ => ('Llega en', 'Calculando…'),
    };
    final duration = reduceMotionOf(context) ? Duration.zero : AppMotion.move;

    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.postaOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(order.status),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caption, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        big,
                        style: theme.textTheme.displaySmall?.copyWith(fontFeatures: AppTypography.tabularFigures, height: 1.1),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: LiveTag(
                    label: statusTag(order.status),
                    live: !order.status.isFinal,
                    color: delivered ? chaski.success : (cancelled ? chaski.danger : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(order.headline, style: theme.textTheme.titleMedium),
            Text(order.detail, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.courier});

  final Courier courier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.xxs, AppSpacing.xs),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: courier.avatarUrl,
            initials: courier.name.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join(),
            seed: courier.name,
            variant: AppAvatarVariant.courier,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courier.name, style: theme.textTheme.titleSmall),
                Text(
                  [courier.vehicle, if (courier.since != null) 'Reparte en Espinar desde ${courier.since}'].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          CircleAction(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Escribir a ${courier.firstName}',
            onPressed: () => AppToast.show(context, 'Muy pronto: mensajes con ${courier.firstName} sin salir de la app.'),
          ),
          CircleAction(
            icon: Icons.call_rounded,
            tooltip: 'Llamar a ${courier.firstName}',
            onPressed: () => AppToast.show(context, 'Muy pronto: llamadas sin compartir tu número.'),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: AppRadius.tile,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          child: Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Detalle del pedido · ${order.code}', style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${order.itemCount} productos · ${Formatters.money(order.total)} · ${order.payment.label}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, child: Text('${line.quantity}×', style: theme.textTheme.labelLarge)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.name, style: theme.textTheme.bodyMedium),
                        if (line.description.isNotEmpty) Text(line.description, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.money(line.total),
                    style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppTypography.tabularFigures),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _kv('Envío', Formatters.money(order.deliveryFee), muted),
          if (!order.discount.isZero)
            _kv('Descuento', '− ${Formatters.money(order.discount)}', muted?.copyWith(color: context.chaski.success)),
          if (!order.tip.isZero) _kv('Propina', Formatters.money(order.tip), muted),
          _kv('Total', Formatters.money(order.total), AppTypography.price(context, size: 16)),
          const SizedBox(height: AppSpacing.sm),
          _kv('Entregar en', '${order.addressTitle} · ${order.addressStreet}', muted),
          if (order.payment case CashPayment(:final changeFor?)) _kv('Vuelto de', Formatters.money(changeFor), muted),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(k, style: style)),
        Flexible(
          child: Text(v, style: style, textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

/// Carga: mapa gris y la hoja con bloques que brillan.
class _TrackingSkeleton extends StatelessWidget {
  const _TrackingSkeleton();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu pedido')),
      body: Semantics(
        label: 'Buscando tu pedido',
        child: Skeleton(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            children: [
              SkeletonBox(height: height * 0.3, borderRadius: AppRadius.card),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(width: 80),
              const SizedBox(height: AppSpacing.xs),
              const SkeletonBox(width: 160, height: 32),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonLines(lines: 4),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(height: 64, borderRadius: AppRadius.card),
            ],
          ),
        ),
      ),
    );
  }
}
