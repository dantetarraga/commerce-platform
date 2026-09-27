import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/partner_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tiempo que tiene el negocio para responder una comanda nueva.
const merchantResponseWindow = Duration(minutes: 8);

/// Lo que el backend suma a la preparación para estimar la llegada al cliente.
const _deliveryAllowance = Duration(minutes: 15);

/// Una comanda de papel: se acepta mandándola al fogón con su tiempo, se marca
/// lista para recoger y, ya lista, muestra quién viene por ella.
class MerchantOrderCard extends ConsumerStatefulWidget {
  const MerchantOrderCard({required this.order, super.key});

  final StaffOrder order;

  @override
  ConsumerState<MerchantOrderCard> createState() => _MerchantOrderCardState();
}

class _MerchantOrderCardState extends ConsumerState<MerchantOrderCard> {
  var _busy = false;
  var _minutes = 20;

  Future<void> _run(
    Future<Failure?> Function(MerchantOrderActions actions) action,
    String done,
  ) async {
    setState(() => _busy = true);
    final failure = await action(
      ref.read(merchantOrderActionsProvider.notifier),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      failure?.message ?? done,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }

  Future<void> _accept() => _run(
    (a) => a.accept(widget.order.id, prepMinutes: _minutes),
    'Al fogón. Avisamos al cliente.',
  );

  Future<void> _reject() async {
    final reason = await showAppBottomSheet<String>(
      context,
      title: '¿Por qué lo rechazas?',
      builder: (_) => const SingleChildScrollView(child: _RejectSheet()),
    );
    if (reason == null) return;
    await _run(
      (a) => a.reject(widget.order.id, reason: reason),
      'Pedido rechazado. Avisamos al cliente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.status;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x1F2A1A14), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: _ComandaHeader(order: order),
          ),
          const TicketPerforation(),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: _ComandaLines(order: order.order),
          ),
          if (!status.isFinal) ...[
            const TicketPerforation(),
            TicketSection(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              child: switch (status) {
                OrderStatus.received => _NewActions(
                  minutes: _minutes,
                  busy: _busy,
                  onMinutes: (m) => setState(() => _minutes = m),
                  onAccept: _accept,
                  onReject: _reject,
                ),
                OrderStatus.confirmed || OrderStatus.preparing => _CookingActions(
                  order: order,
                  busy: _busy,
                  onReady: () => _run(
                    (a) => a.markReady(order.id),
                    'Lista. Avisamos a los repartidores.',
                  ),
                ),
                _ => _PickupInfo(order: order),
              },
            ),
          ] else if (order.cancelReason != null)
            TicketSection(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
  OrderStatus.received => 'COMANDA NUEVA',
  OrderStatus.confirmed || OrderStatus.preparing => 'EN FOGÓN',
  OrderStatus.ready => 'LISTA · ESPERA REPARTIDOR',
  OrderStatus.courierAssigned => 'LISTA · REPARTIDOR EN CAMINO',
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
      if (distance > 0 && distance < 1000) '$distance m' else if (distance >= 1000) Formatters.distance(distance / 1000),
      staffTimeAgo(order.order.placedAt),
    ].join(' · ');
    final trailing = switch (status) {
      OrderStatus.received => CountdownRing(
        deadline: order.order.placedAt.add(merchantResponseWindow),
        total: merchantResponseWindow,
      ),
      OrderStatus.ready || OrderStatus.courierAssigned => const PartnerStamp('LISTA', color: AppColors.hierba),
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
                style: theme.textTheme.labelSmall?.copyWith(
                  color: status == OrderStatus.received ? scheme.primary : scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                order.order.code,
                style: TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: scheme.onSurface,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing],
      ],
    );
  }
}

class _ComandaLines extends StatelessWidget {
  const _ComandaLines({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
    final payment = order.payment;
    final change = payment is CashPayment && payment.changeFor != null
        ? ' · paga con ${Formatters.money(payment.changeFor!)}'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in order.lines) ...[
          const SizedBox(height: 6),
          LeaderRow(
            leading: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text('${line.quantity}×', style: item?.copyWith(color: scheme.primary)),
            ),
            label: Text(line.name, style: item),
            value: Text(Formatters.money(line.total), style: item?.copyWith(fontFeatures: AppTypography.tabularFigures)),
          ),
          if (line.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(line.description, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          if (line.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 3),
              child: _NoteChip('“${line.notes}”'),
            ),
        ],
        if (order.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _NoteChip('Nota: ${order.notes}'),
          ),
        const SizedBox(height: 10),
        LeaderRow(
          label: Text(
            '${payment.label}$change',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          value: Text(Formatters.money(order.total), style: AppTypography.price(context)),
        ),
      ],
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(7),
            topRight: Radius.circular(7),
            bottomRight: Radius.circular(7),
            bottomLeft: Radius.circular(2),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
        ),
      ),
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
    final accept = AppButton(
      label: 'Al fogón · $minutes min',
      loading: busy,
      onPressed: busy ? null : onAccept,
    );
    final reject = AppButton.secondary(label: 'Rechazar', onPressed: busy ? null : onReject);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sale del fogón en',
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in prepTimeChoices)
              AppChip(label: '$m min', selected: m == minutes, onTap: busy ? null : () => onMinutes(m)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(14) > 20;
            if (narrow) {
              return Column(children: [accept, const SizedBox(height: AppSpacing.xs), reject]);
            }
            return Row(
              children: [
                Expanded(child: reject),
                const SizedBox(width: 8),
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
class _CookingActions extends StatelessWidget {
  const _CookingActions({required this.order, required this.busy, required this.onReady});

  final StaffOrder order;
  final bool busy;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final started = order.order.events
            .where((e) => e.status == OrderStatus.confirmed || e.status == OrderStatus.preparing)
            .map((e) => e.at)
            .firstOrNull ??
        order.order.placedAt;
    final eta = order.order.estimatedArrival;
    final readyBy = eta?.subtract(_deliveryAllowance);
    double? progress;
    var due = 'En fogón desde ${Formatters.clock(started)}';
    var late = false;
    if (readyBy != null && readyBy.isAfter(started)) {
      final total = readyBy.difference(started).inSeconds;
      progress = (now.difference(started).inSeconds / total).clamp(0.0, 1.0);
      final left = readyBy.difference(now).inMinutes;
      late = now.isAfter(readyBy);
      due = late ? 'se pasó ${-left} min' : 'faltan ${left < 1 ? 1 : left} min';
    }
    final color = late ? context.chaski.danger : scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'En fogón desde ${Formatters.clock(started)}',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (progress != null)
              Text(due, style: theme.textTheme.labelLarge?.copyWith(color: late ? color : scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          ExcludeSemantics(child: _ProgressTrail(progress: progress, color: color)),
        ],
        const SizedBox(height: 12),
        _InkButton(label: 'Lista para recoger', busy: busy, onPressed: busy ? null : onReady),
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
            Positioned.fill(
              child: Center(child: DottedLine(color: Theme.of(context).colorScheme.outlineVariant, radius: 1.2, gap: 6)),
            ),
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

class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark ? scheme.onSurface : AppColors.tinta;
    final fg = Theme.of(context).brightness == Brightness.dark ? scheme.surface : AppColors.blanco;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: AppRadius.button,
        child: InkWell(
          borderRadius: AppRadius.button,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: busy
                ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
                : Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

/// Lista: quién viene por ella, el trazo de su llegada y el código de entrega.
class _PickupInfo extends StatelessWidget {
  const _PickupInfo({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final courier = order.order.courier;
    final code = order.order.code.replaceAll('#', '');
    final bags = order.order.itemCount > 3 ? '2 bolsas' : '1 bolsa';
    final (title, subtitle, reach) = switch (order.status) {
      OrderStatus.ready => ('Esperando repartidor', 'Avisamos a los repartidores de Yauri', 0.15),
      OrderStatus.courierAssigned => ('${courier?.firstName ?? 'El repartidor'} viene por el pedido', courier?.vehicle ?? '', 0.7),
      _ => ('${courier?.firstName ?? 'El repartidor'} lo lleva al cliente', courier?.vehicle ?? '', 1.0),
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
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Entrega $bags · código ',
            children: [TextSpan(text: code, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800))],
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Punto verde (repartidor) → moto → tienda, sobre el trazo punteado.
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
              Positioned(left: 6, right: 6, top: 7, child: DottedLine(color: scheme.primary, gap: 6)),
              Positioned(
                left: 0,
                top: 3,
                child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.hierba, shape: BoxShape.circle)),
              ),
              Positioned(
                left: x,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
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

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _detail = TextEditingController();
  String? _reason;

  @override
  void initState() {
    super.initState();
    _detail.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  /// "Sin stock: Pollo entero" · "Cocina llena" · el texto libre si no eligió.
  String? get _result {
    final detail = _detail.text.trim();
    if (_reason == null) return detail.length >= 3 ? detail : null;
    return detail.isEmpty ? _reason : '$_reason: $detail';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final r in rejectReasons)
                  AppChip(
                    label: r,
                    selected: r == _reason,
                    onTap: () => setState(() => _reason = _reason == r ? null : r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: _reason == 'Sin stock' ? '¿Qué producto falta?' : 'Detalle (opcional)',
              controller: _detail,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El cliente verá este motivo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.danger(
              label: 'Rechazar pedido',
              onPressed: result == null ? null : () => Navigator.of(context).pop(result),
            ),
          ],
        ),
      ),
    );
  }
}
