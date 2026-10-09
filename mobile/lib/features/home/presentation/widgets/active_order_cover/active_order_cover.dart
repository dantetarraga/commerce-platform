import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/core/time/clock_provider.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/home/presentation/widgets/active_order_cover/live_dot.dart';
import 'package:apamuy/features/home/presentation/widgets/active_order_cover/mini_map.dart';
import 'package:apamuy/features/home/presentation/widgets/active_order_cover/step_trail.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/maps/delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Seguimiento a todo el ancho bajo la barra compacta: estado, minutos, mapa
/// ilustrado, los cuatro pasos con su hora y quién lo lleva.
class ActiveOrderCover extends ConsumerWidget {
  const ActiveOrderCover({required this.order, super.key});

  final Order order;

  /// Avance ilustrativo sobre la ruta por paso.
  static double _progress(int step) => switch (step) {
    0 => 0.02,
    1 => 0.12,
    2 => 0.55,
    _ => 0.92,
  };

  void _open(BuildContext context) => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id});

  void _help(BuildContext context) => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': order.id});

  String? _time(OrderStatus status) => switch (order.timeOf(status)) {
    final at? => Formatters.clock(at),
    null => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final minutes = order.minutesLeft(now);
    final step = order.activeStep(now);
    final status = order.status == OrderStatus.onTheWay && step == 3 ? activeStepLabels[3] : order.status.label;
    final arrival = order.estimatedArrival;
    return Semantics(
      container: true,
      label: '${order.store.name}. ${order.headline}${minutes == null ? '' : '. Llega en $minutes minutos'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, AppSpacing.gutter),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.hero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LiveDot(color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                const Spacer(),
                AppNetworkImage(
                  url: order.store.logoUrl,
                  width: 24,
                  height: 24,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  fallbackIcon: Icons.storefront_rounded,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    order.store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (minutes != null) ...[
                  Text('$minutes', style: AppTypography.price(context, size: 72).copyWith(height: 0.88, color: scheme.onSurface)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('min', style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  if (arrival != null) Expanded(child: _ArrivesAt(arrival)) else const Spacer(),
                ] else ...[
                  Expanded(child: Text(order.headline, style: theme.textTheme.headlineSmall)),
                  if (arrival != null) _ArrivesAt(arrival),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(minutes == null ? order.detail : order.headline, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Ver el recorrido en el mapa',
              onTap: () => _open(context),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _open(context),
                child: ClipRRect(
                  borderRadius: AppRadius.tileExit,
                  child: SizedBox(
                    height: 148,
                    child: _CoverMap(order: order, step: step, progress: _progress(step)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            StepTrail(
              step: step,
              labels: activeStepLabelsFor(order.status),
              times: [
                _time(OrderStatus.confirmed) ?? _time(OrderStatus.received),
                _time(OrderStatus.preparing),
                _time(OrderStatus.onTheWay) ?? _time(OrderStatus.courierAssigned),
                _time(OrderStatus.delivered),
              ],
            ),
            const SizedBox(height: 14),
            _CourierStrip(courier: order.courier, onHelp: () => _help(context), onMap: () => _open(context)),
          ],
        ),
      ),
    );
  }
}

/// "Llega 6:30 pm" alineado a la derecha; se achica antes que desbordar.
class _ArrivesAt extends StatelessWidget {
  const _ArrivesAt(this.arrival);

  final DateTime arrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Llega', style: theme.textTheme.bodySmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(Formatters.clock(arrival), maxLines: 1, style: theme.textTheme.titleLarge),
        ),
      ],
    );
  }
}

/// Quién lo lleva, con ayuda y mapa.
class _CourierStrip extends StatelessWidget {
  const _CourierStrip({required this.courier, required this.onHelp, required this.onMap});

  final Courier? courier;
  final VoidCallback onHelp;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final courier = this.courier;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: context.apamuy.card, borderRadius: AppRadius.tileExit),
      child: Row(
        children: [
          if (courier != null)
            AppAvatar(imageUrl: courier.avatarUrl, seed: courier.name, size: 46)
          else
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.outline, width: 2)),
              child: Icon(Icons.moped_rounded, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier != null ? '${courier.firstName} te lo lleva' : 'Buscando repartidor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  courier != null ? courier.vehicle : 'Te avisamos al asignarlo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _SquareAction(icon: Icons.chat_bubble_outline_rounded, tooltip: 'Ayuda con tu pedido', filled: false, onTap: onHelp),
          const SizedBox(width: 8),
          _SquareAction(icon: Icons.map_outlined, tooltip: 'Ver mapa', filled: true, onTap: onMap),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.icon, required this.tooltip, required this.filled, required this.onTap});

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : scheme.primaryContainer,
      borderRadius: AppRadius.button,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: filled ? scheme.onPrimary : scheme.primary),
      ),
    );
  }
}

/// Vista previa del recorrido: Google Maps (imagen fija, sin gestos) con el negocio,
/// tu puerta y la moto en camino; sin coordenadas o sin Google Maps, el plano dibujado.
class _CoverMap extends StatelessWidget {
  const _CoverMap({required this.order, required this.step, required this.progress});

  final Order order;
  final int step;
  final double progress;

  static MapCoordinate? _map(GeoCoordinates? at) => at == null ? null : MapCoordinate(at.latitude, at.longitude);

  @override
  Widget build(BuildContext context) {
    final store = _map(order.store.location);
    final destination = _map(order.destination);
    final showRider = order.courier != null && step >= 2;
    if (!googleMapsSupported || store == null || destination == null) {
      return MiniMap(progress: progress, showRider: showRider, logoUrl: order.store.logoUrl);
    }
    // El toque lo recibe la tarjeta (abre el seguimiento), no el mapa.
    return IgnorePointer(
      child: DeliveryMap(
        data: DeliveryMapData(
          estimatedProgress: progress,
          showCourier: showRider,
          storeLabel: order.store.name,
          destinationLabel: order.addressTitle,
          store: store,
          destination: destination,
          courier: order.status == OrderStatus.onTheWay ? _map(order.courier?.position?.coordinates) : null,
          compact: true,
        ),
      ),
    );
  }
}
