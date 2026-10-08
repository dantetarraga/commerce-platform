import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant_board.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// Comanda lista: quién viene por ella, el trazo de su llegada y el código de entrega.
class PickupInfo extends StatelessWidget {
  const PickupInfo({required this.order, super.key});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final courier = order.order.courier;
    final who = courier?.firstName ?? 'El repartidor';
    final (title, subtitle, reach) = switch (order.status) {
      OrderStatus.ready => ('Esperando repartidor', 'Avisamos a los repartidores de $cityName', 0.15),
      OrderStatus.courierAssigned => ('$who viene por el pedido', courier?.vehicle ?? '', 0.7),
      _ => ('$who lo lleva al cliente', courier?.vehicle ?? '', 1.0),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (courier != null)
              AppNetworkImage(
                url: courier.avatarUrl,
                width: 40,
                height: 40,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                fallbackIcon: Icons.two_wheeler_rounded,
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.hourglass_top_rounded, size: 20, color: scheme.primary),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (subtitle.isNotEmpty) Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(child: _CourierRoute(reach: reach)),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            text: 'Entrega ${order.bagCount == 1 ? '1 bolsa' : '${order.bagCount} bolsas'} · código ',
            children: [
              TextSpan(text: order.order.shortCode, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
            ],
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Punto del repartidor → moto → tienda, sobre el trazo punteado.
class _CourierRoute extends StatelessWidget {
  const _CourierRoute({required this.reach});

  final double reach;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final x = 6 + (constraints.maxWidth - 36) * reach;
          return Stack(
            children: [
              Positioned(left: 6, right: 6, top: 8, child: TrackLine(color: scheme.primary.withValues(alpha: 0.35))),
              Positioned(
                left: 0,
                top: 3,
                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: context.apamuy.accent, shape: BoxShape.circle)),
              ),
              Positioned(
                left: x,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: AppRadius.exit(6, cut: 2)),
                ),
              ),
              Positioned(
                right: 0,
                top: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.ticketPaper,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
