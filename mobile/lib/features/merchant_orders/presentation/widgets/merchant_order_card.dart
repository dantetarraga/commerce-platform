import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un pedido del negocio con las acciones de su estado: aceptar o rechazar
/// (nuevo), marcar listo (preparando) o esperar al repartidor (listo).
class MerchantOrderCard extends ConsumerStatefulWidget {
  const MerchantOrderCard({required this.order, super.key});

  final StaffOrder order;

  @override
  ConsumerState<MerchantOrderCard> createState() => _MerchantOrderCardState();
}

class _MerchantOrderCardState extends ConsumerState<MerchantOrderCard> {
  var _busy = false;

  Future<void> _run(Future<Failure?> Function(MerchantOrderActions actions) action, String done) async {
    setState(() => _busy = true);
    final failure = await action(ref.read(merchantOrderActionsProvider.notifier));
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(context, failure?.message ?? done, kind: failure == null ? AppToastKind.success : AppToastKind.error);
  }

  Future<void> _accept() async {
    final minutes = await showAppBottomSheet<int>(
      context,
      title: '¿En cuánto estará listo?',
      builder: (_) => const _PrepTimeSheet(),
    );
    if (minutes == null) return;
    await _run((a) => a.accept(widget.order.id, prepMinutes: minutes), 'Aceptado. Avisamos al cliente.');
  }

  Future<void> _reject() async {
    final reason = await showAppBottomSheet<String>(
      context,
      title: '¿Por qué lo rechazas?',
      builder: (_) => const _RejectSheet(),
    );
    if (reason == null) return;
    await _run((a) => a.reject(widget.order.id, reason: reason), 'Pedido rechazado. Avisamos al cliente.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final courier = order.order.courier;
    return AppCard(
      variant: AppCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffOrderHeader(order: order),
          const SizedBox(height: AppSpacing.xxs),
          Text(order.customerName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          StaffOrderLines(order: order.order),
          const Divider(height: AppSpacing.lg),
          StaffOrderPayment(order: order.order),
          const SizedBox(height: AppSpacing.sm),
          switch (order.status) {
            OrderStatus.received => Row(
              children: [
                Expanded(
                  child: AppButton.secondary(label: 'Rechazar', onPressed: _busy ? null : _reject),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppButton(label: 'Aceptar', loading: _busy, onPressed: _busy ? null : _accept),
                ),
              ],
            ),
            OrderStatus.confirmed || OrderStatus.preparing => AppButton(
              label: 'Marcar listo',
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () => _run((a) => a.markReady(order.id), 'Listo. Avisamos a los repartidores.'),
            ),
            OrderStatus.ready => Text(
              'Esperando que un repartidor lo tome.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            OrderStatus.courierAssigned || OrderStatus.onTheWay => Text(
              '${courier?.firstName ?? 'El repartidor'} · ${order.status.staffLabel.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            OrderStatus.delivered || OrderStatus.cancelled => Text(
              order.cancelReason == null ? order.status.staffLabel : 'Cancelado: ${order.cancelReason}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          },
        ],
      ),
    );
  }
}

class _PrepTimeSheet extends StatefulWidget {
  const _PrepTimeSheet();

  @override
  State<_PrepTimeSheet> createState() => _PrepTimeSheetState();
}

class _PrepTimeSheetState extends State<_PrepTimeSheet> {
  var _minutes = 20;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in prepTimeChoices)
                  AppChip(label: '$m min', selected: m == _minutes, onTap: () => setState(() => _minutes = m)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Aceptar · $_minutes min', onPressed: () => Navigator.of(context).pop(_minutes)),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
