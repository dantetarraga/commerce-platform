import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/presentation/order_status_labels.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pasos del seguimiento, cada uno con su hora (la entrega, con la estimada).
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) => AppQuipu(dense: true, steps: _steps());

  String? _clockOf(OrderStatus s) => switch (order.timeOf(s)) {
    final at? => Formatters.clock(at),
    null => null,
  };

  List<QuipuStep> _steps() {
    final cancelled = order.status == OrderStatus.cancelled;
    final eta = order.estimatedArrival;
    return [
      for (final s in OrderStatus.timeline)
        if (!cancelled || order.timeOf(s) != null)
          QuipuStep(
            title: order.stepTitle(s),
            trailing: _clockOf(s) ?? (s == OrderStatus.delivered && eta != null && order.isActive ? '~${Formatters.clock(eta)}' : null),
            knot: order.status == s && !s.isFinal
                ? QuipuKnot.current
                : order.reached(s)
                ? QuipuKnot.done
                : QuipuKnot.todo,
          ),
      if (cancelled) QuipuStep(title: order.stepTitle(OrderStatus.cancelled), trailing: _clockOf(OrderStatus.cancelled), knot: QuipuKnot.done),
    ];
  }
}
