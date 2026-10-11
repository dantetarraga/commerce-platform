import 'package:apamuy/core/time/clock_provider.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/domain/order_insights.dart';
import 'package:apamuy/features/orders/presentation/widgets/order_stage_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El riel de íconos de un pedido; en camino, la línea hacia la casa avanza con
/// el repartidor. Lo comparten el seguimiento y la portada del inicio.
class OrderProgressRail extends ConsumerWidget {
  const OrderProgressRail({required this.order, super.key});

  final Order order;

  /// Tramo del riel (no se usa con el pedido cancelado).
  static int stageOf(OrderStatus status) => switch (status) {
    OrderStatus.received || OrderStatus.confirmed || OrderStatus.cancelled => 0,
    OrderStatus.preparing || OrderStatus.ready => 1,
    OrderStatus.courierAssigned || OrderStatus.onTheWay => 2,
    OrderStatus.delivered => 3,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onTheWay = order.status == OrderStatus.onTheWay;
    // Solo en camino hace falta el reloj: la línea avanza sola.
    final now = onTheWay ? ref.watch(clockProvider).value ?? DateTime.now() : DateTime.now();
    return OrderStageTrack(
      current: stageOf(order.status),
      travel: onTheWay ? order.routeProgress(now) : null,
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
