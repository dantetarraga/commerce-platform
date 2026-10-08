import 'package:chaski/core/time/clock_provider.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/pickup_info.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/reject_sheet.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tiempo que tiene el negocio para responder una comanda nueva.
const merchantResponseWindow = Duration(minutes: 8);

/// Una comanda de papel: se acepta mandándola al fogón con su tiempo, se marca
/// lista para recoger y, ya lista, muestra quién viene por ella.
class MerchantOrderCard extends ConsumerStatefulWidget {
  const MerchantOrderCard({required this.order, super.key});

  final StaffOrder order;

  @override
  ConsumerState<MerchantOrderCard> createState() => _MerchantOrderCardState();
}

class _MerchantOrderCardState extends ConsumerState<MerchantOrderCard> with PartnerActionRunner {
  var _minutes = 20;

  MerchantOrderActions get _actions => ref.read(merchantOrderActionsProvider.notifier);

  Future<void> _accept() =>
      run(() => _actions.accept(widget.order.id, prepMinutes: _minutes), success: 'Aceptado. Le avisamos al cliente.');

  Future<void> _ready() => run(() => _actions.markReady(widget.order.id), success: 'Listo. Avisamos a los repartidores.');

  Future<void> _reject() async {
    final reason = await showAppBottomSheet<String>(
      context,
      title: '¿Por qué lo rechazas?',
      builder: (_) => const SingleChildScrollView(child: RejectSheet()),
    );
    if (reason == null || !mounted) return;
    await run(() => _actions.reject(widget.order.id, reason: reason), success: 'Pedido rechazado. Avisamos al cliente.');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.status;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadows.lifted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, AppSpacing.xxs),
            child: _ComandaHeader(order: order),
          ),
          const TicketPerforation(),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 2, AppSpacing.md, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaffOrderLines(order: order.order),
                const SizedBox(height: 10),
                StaffOrderPayment(order: order.order),
              ],
            ),
          ),
          if (!status.isFinal) ...[
            const TicketPerforation(),
            TicketSection(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 2, AppSpacing.md, 14),
              child: switch (status) {
                OrderStatus.received => _NewActions(
                  minutes: _minutes,
                  busy: busy,
                  onMinutes: (m) => setState(() => _minutes = m),
                  onAccept: _accept,
                  onReject: _reject,
                ),
                OrderStatus.confirmed || OrderStatus.preparing => _CookingActions(order: order, busy: busy, onReady: _ready),
                _ => PickupInfo(order: order),
              },
            ),
          ] else if (order.cancelReason != null)
            TicketSection(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text(
                'Cancelado: ${order.cancelReason}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.chaski.danger),
              ),
            ),
          const TicketEdge(top: false),
        ],
      ),
    );
  }
}

String _eyebrow(OrderStatus status) => switch (status) {
  OrderStatus.received => 'PEDIDO NUEVO',
  OrderStatus.confirmed || OrderStatus.preparing => 'PREPARANDO',
  OrderStatus.ready => 'LISTO · ESPERA REPARTIDOR',
  OrderStatus.courierAssigned => 'LISTO · REPARTIDOR EN CAMINO',
  OrderStatus.onTheWay => 'EN CAMINO AL CLIENTE',
  OrderStatus.delivered => 'ENTREGADA',
  OrderStatus.cancelled => 'CANCELADA',
};

class _ComandaHeader extends StatelessWidget {
  const _ComandaHeader({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = order.status;
    final distance = order.distanceMeters;
    final meta = [
      order.customerName,
      if (distance > 0) Formatters.meters(distance),
      staffTimeAgo(order.order.placedAt),
    ].join(' · ');
    final trailing = switch (status) {
      OrderStatus.received => CountdownRing(deadline: order.order.placedAt.add(merchantResponseWindow), total: merchantResponseWindow),
      OrderStatus.ready || OrderStatus.courierAssigned => PartnerStamp('LISTO', color: context.chaski.accent),
      OrderStatus.delivered => PartnerStamp('ENTREGADA', color: scheme.onSurfaceVariant, size: 11),
      OrderStatus.cancelled => PartnerStamp('CANCELADA', color: context.chaski.danger, size: 11),
      _ => null,
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _eyebrow(status),
                style: AppTypography.eyebrow(context).copyWith(
                  color: status == OrderStatus.received ? scheme.primary : null,
                  letterSpacing: 1.2,
                ),
              ),
              Text(order.order.code, style: AppTypography.displayStyle(context, size: 30, weight: FontWeight.w800, height: 1.05, tabular: true)),
              Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing],
      ],
    );
  }
}

/// "Sale del fogón en" 10/20/30/45 · Rechazar · Al fogón · N min.
class _NewActions extends StatelessWidget {
  const _NewActions({
    required this.minutes,
    required this.busy,
    required this.onMinutes,
    required this.onAccept,
    required this.onReject,
  });

  final int minutes;
  final bool busy;
  final ValueChanged<int> onMinutes;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accept = AppButton(label: 'Aceptar · listo en $minutes min', loading: busy, onPressed: busy ? null : onAccept);
    final reject = AppButton.secondary(label: 'Rechazar', onPressed: busy ? null : onReject);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Listo en', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in prepTimeChoices)
              AppChip(label: '$m min', selected: m == minutes, onTap: busy ? null : () => onMinutes(m)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            if (!PartnerLayout.isWide(context, minWidth: PartnerLayout.sideBySide, width: constraints.maxWidth)) {
              return Column(children: [accept, const SizedBox(height: AppSpacing.xs), reject]);
            }
            return Row(
              children: [
                Expanded(child: reject),
                const SizedBox(width: AppSpacing.xs),
                Expanded(flex: 2, child: accept),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// En fogón: el trazo avanza hasta la hora prometida y se pone rojo si se pasa.
class _CookingActions extends ConsumerWidget {
  const _CookingActions({required this.order, required this.busy, required this.onReady});

  final StaffOrder order;
  final bool busy;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prep = PrepProgress.of(order, ref.watch(clockProvider).value ?? DateTime.now());
    final fraction = prep.fraction;
    final color = prep.isLate ? context.chaski.danger : scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Preparando desde ${Formatters.clock(prep.startedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (prep.dueLabel case final due?)
              Text(
                due,
                style: theme.textTheme.labelLarge?.copyWith(color: prep.isLate ? color : scheme.onSurfaceVariant, fontWeight: FontWeight.w800),
              ),
          ],
        ),
        if (fraction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(child: _ProgressTrail(progress: fraction, color: color)),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton.ink(label: 'Listo para recoger', loading: busy, onPressed: busy ? null : onReady),
      ],
    );
  }
}

class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 12,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final x = (constraints.maxWidth - 12) * progress;
        return Stack(
          children: [
            const Positioned.fill(child: TrackLine(thickness: 4)),
            Positioned(
              left: 0,
              top: 4,
              width: x + 6,
              height: 4,
              child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            ),
            Positioned(
              left: x,
              top: 0,
              child: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ),
          ],
        );
      },
    ),
  );
}
