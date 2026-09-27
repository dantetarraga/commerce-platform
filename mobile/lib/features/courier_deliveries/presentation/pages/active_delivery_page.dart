import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/external_links.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El pedido que lleva el repartidor, en dos pasos: recoger en el negocio y
/// entregar al cliente cobrando contraentrega.
class ActiveDeliveryPage extends ConsumerStatefulWidget {
  const ActiveDeliveryPage({required this.orderId, super.key});

  static const name = 'activeDelivery';

  final String orderId;

  @override
  ConsumerState<ActiveDeliveryPage> createState() => _ActiveDeliveryPageState();
}

class _ActiveDeliveryPageState extends ConsumerState<ActiveDeliveryPage> {
  var _busy = false;

  Future<void> _pickedUp(StaffOrder order) async {
    setState(() => _busy = true);
    final failure = await ref.read(courierActionsProvider.notifier).pickedUp(order.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  Future<void> _deliver(StaffOrder order) async {
    final collected = await showAppBottomSheet<(CollectionMethod, Money)>(
      context,
      title: '¿Cómo pagó ${order.customerName.split(' ').first}?',
      builder: (_) => SingleChildScrollView(child: _CollectSheet(order: order)),
    );
    if (collected == null || !mounted) return;
    setState(() => _busy = true);
    final (method, amount) = collected;
    final failure = await ref.read(courierActionsProvider.notifier).delivered(order.id, method: method, amount: amount);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
      return;
    }
    AppToast.show(
      context,
      'Entregado. ¡Buen trabajo!',
      kind: AppToastKind.success,
      leading: const AppRiveSuccess(size: 40),
    );
    Navigator.of(context).pop();
  }

  Future<void> _open(Future<bool> Function() launch) async {
    final opened = await launch();
    if (!opened && mounted) AppToast.show(context, 'No pudimos abrir esa app en este celular.');
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(courierActiveDeliveryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido en curso')),
      body: AsyncValueView(
        value: delivery,
        onRetry: () => ref.invalidate(courierActiveDeliveryProvider),
        loading: const Center(child: CircularProgressIndicator()),
        isEmpty: (order) => order == null || order.id != widget.orderId,
        empty: const AppEmptyState(
          title: 'Este pedido ya no está en curso',
          message: 'Vuelve al inicio para ver otros.',
        ),
        data: (order) => _content(context, order!),
      ),
    );
  }

  Widget _content(BuildContext context, StaffOrder order) {
    final theme = Theme.of(context);
    final pickingUp = order.status == OrderStatus.courierAssigned;
    final payment = order.order.payment;
    final change = payment is CashPayment && payment.changeFor != null
        ? Money(payment.changeFor!.cents - order.order.total.cents)
        : null;

    return SafeArea(
      child: PartnerContent(
        maxWidth: 760,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: [
                  StaffOrderHeader(order: order),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: AppRadius.tile,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: pickingUp ? theme.colorScheme.outlineVariant : theme.colorScheme.primary,
                            borderRadius: AppRadius.tile,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PartnerSectionHeading(
                    title: pickingUp ? 'Recoge el pedido' : 'Entrega y cobra',
                    subtitle: pickingUp
                        ? 'Paso 1 de 2 · Confirma que llevas todo.'
                        : 'Paso 2 de 2 · Confirma el pago al entregar.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Step(
                    number: 1,
                    done: !pickingUp,
                    current: pickingUp,
                    label: pickingUp ? 'RECOGIDA' : 'RECOGIDO',
                    title: order.order.store.name,
                    subtitle: order.pickup.address,
                    onCall: order.pickup.phone == null
                        ? null
                        : () => _open(
                            () => ExternalLinks.call(
                              order.pickup.phone!.replaceAll(' ', ''),
                            ),
                          ),
                    onMap: () => _open(() => _map(order.pickup.location)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Step(
                    number: 2,
                    done: false,
                    current: !pickingUp,
                    label: 'ENTREGA',
                    title: order.customerName,
                    subtitle: [
                      order.order.addressStreet,
                      if (order.order.addressReference.isNotEmpty) order.order.addressReference,
                    ].join(' · '),
                    onCall: () => _open(() => ExternalLinks.call(order.customerPhone)),
                    onMap: () => _open(() => _map(order.deliveryLocation)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: AppRadius.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cobrar al entregar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          Formatters.money(order.order.total),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          change != null && change.cents > 0
                              ? '${payment.label}: paga con ${Formatters.money((payment as CashPayment).changeFor!)} · '
                                    'lleva ${Formatters.money(change)} de vuelto'
                              : payment.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Lo que llevas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  PartnerSurface(child: StaffOrderLines(order: order.order)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              child: pickingUp
                  ? AppButton(
                      label: 'Lo recogí',
                      icon: Icons.shopping_bag_outlined,
                      loading: _busy,
                      onPressed: _busy ? null : () => _pickedUp(order),
                    )
                  : AppButton(
                      label: 'Entregado',
                      icon: Icons.check_rounded,
                      loading: _busy,
                      onPressed: _busy ? null : () => _deliver(order),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _map(GeoCoordinates at) => ExternalLinks.map(at.latitude, at.longitude);
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.done,
    required this.current,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onMap,
    this.onCall,
  });

  final int number;
  final bool done;
  final bool current;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onMap;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PartnerSurface(
      highlighted: current,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done || current ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
            child: done
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text(
                    '$number',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: current ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: current ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                if (!done)
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      if (onCall != null)
                        TextButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Llamar'),
                        ),
                      TextButton.icon(
                        onPressed: onMap,
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Cómo llegar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cómo pagó el cliente y cuánto recibió (por defecto, el total).
class _CollectSheet extends StatefulWidget {
  const _CollectSheet({required this.order});

  final StaffOrder order;

  @override
  State<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<_CollectSheet> {
  late CollectionMethod _method = CollectionMethod.from(
    widget.order.order.payment,
  );
  late final _amount = TextEditingController(
    text: (widget.order.order.total.cents / 100).toStringAsFixed(2),
  );

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Money? get _parsed {
    final value = double.tryParse(_amount.text.replaceAll(',', '.').trim());
    if (value == null || !value.isFinite || value < 0) return null;
    return Money((value * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _parsed;
    final total = widget.order.order.total;
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
            Text('Total del pedido', style: theme.textTheme.bodyMedium),
            Text(Formatters.money(total), style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Medio de pago recibido', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in CollectionMethod.values)
                  AppChip(
                    label: m.label,
                    selected: m == _method,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Monto recibido (S/)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: amount == null ? 'Escribe un monto válido' : null,
            ),
            if (amount != null && amount != total) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No coincide con el total (${Formatters.money(total)}). Se registrará igual.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Confirmar entrega',
              onPressed: amount == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact().ignore();
                      Navigator.of(context).pop((_method, amount));
                    },
            ),
          ],
        ),
      ),
    );
  }
}
