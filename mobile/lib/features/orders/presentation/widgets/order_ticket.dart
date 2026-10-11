import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// El pedido como la boleta del checkout: productos y montos; tras la
/// perforación, el total, cómo se paga y adónde va.
class OrderTicket extends StatelessWidget {
  const OrderTicket({required this.order, super.key});

  final Order order;

  String get _paymentLine {
    final how = switch (order.payment) {
      CashPayment() => 'en efectivo',
      CardPayment() => 'con tarjeta',
      final p => 'con ${p.label}',
    };
    return switch (order.status) {
      OrderStatus.delivered => 'Pagaste $how',
      OrderStatus.cancelled => 'No se te cobró nada',
      _ => 'Pagas $how al recibir',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final small = theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Pedido ${order.code}', style: theme.textTheme.titleMedium),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(order.store.name, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LeaderRow(
                        label: Text('${line.quantity} × ${line.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: small),
                        value: Text(Formatters.money(line.total), style: small?.copyWith(fontFeatures: AppTypography.tabularFigures)),
                      ),
                      if (line.description.isNotEmpty) Text(line.description, style: muted),
                    ],
                  ),
                ),
              AmountRow(label: 'Envío', amount: order.deliveryFee, leader: true, freeLabel: 'Gratis'),
              if (!order.discount.isZero) AmountRow.discount(label: 'Descuento', amount: order.discount, leader: true),
              if (!order.tip.isZero) AmountRow(label: 'Propina', amount: order.tip, leader: true),
            ],
          ),
        ),
        const TicketPerforation(),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountRow.total(label: _paymentLine, amount: order.total),
              if (order.payment case CashPayment(:final changeFor?)) AmountRow(label: 'Vuelto de', amount: changeFor),
              const SizedBox(height: AppSpacing.xxs),
              Text('Entregar en ${order.addressTitle} · ${order.addressStreet}', style: muted),
            ],
          ),
        ),
        const TicketEdge(top: false),
      ],
    );
  }
}
