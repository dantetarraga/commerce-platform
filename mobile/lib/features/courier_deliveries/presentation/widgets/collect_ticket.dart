import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Boleta de lo que lleva y lo que cobra al entregar.
class CollectTicket extends StatelessWidget {
  const CollectTicket({required this.order, super.key});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const TicketEdge(top: true),
      TicketSection(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, 6),
        child: StaffOrderLines(order: order.order, title: 'LO QUE LLEVAS', prices: false, dense: true),
      ),
      const TicketPerforation(),
      TicketSection(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 10),
        child: StaffCollectSummary(order: order.order),
      ),
      const TicketEdge(top: false),
    ],
  );
}
