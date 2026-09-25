import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/features/orders/presentation/widgets/order_bits.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "¿Algún problema con tu pedido?": motivos concretos y contacto con soporte.
class OrderHelpPage extends ConsumerWidget {
  const OrderHelpPage({required this.orderId, super.key});

  static const name = 'orderHelp';

  final String orderId;

  static const List<(IconData, String)> _reasons = [
    (Icons.shopping_bag_outlined, 'Falta un producto'),
    (Icons.close_rounded, 'Llegó dañado o equivocado'),
    (Icons.credit_card_rounded, 'Me cobraron mal'),
    (Icons.schedule_rounded, 'Nunca llegó'),
    (Icons.more_horiz_rounded, 'Otro'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final order = ref.watch(orderWatchProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda con tu pedido')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
        children: [
          LoadCrossFade(
            stateKey: switch (order) {
              AsyncValue(hasValue: true) => 'data',
              AsyncError() => 'error',
              _ => 'loading',
            },
            child: switch (order) {
              AsyncValue(:final value?) => _OrderSummaryCard(order: value),
              AsyncError(:final error) => orderLoadError(
                error,
                what: 'el pedido',
                compact: true,
                onRetry: () => ref.invalidate(orderWatchProvider(orderId)),
              ),
              _ => const Skeleton(child: SkeletonBox(height: 72, borderRadius: AppRadius.card)),
            },
          ),
          if (order.value case final value? when value.canBeCancelled) ...[
            const SizedBox(height: AppSpacing.md),
            _CancelOrderButton(order: value),
          ],
          const SizedBox(height: AppSpacing.section),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Semantics(header: true, child: Text('¿QUÉ PASÓ?', style: AppTypography.eyebrow(context))),
          ),
          GroupedCard(
            children: [
              for (final (icon, reason) in _reasons)
                GroupedRow(icon: icon, title: reason, onTap: () => _describe(context, reason, order.value)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Respondemos en menos de 10 minutos, de 7 am a 11 pm.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(
            label: 'Escribir a soporte',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () => _describe(context, 'Escribir a soporte', order.value),
          ),
        ],
      ),
    );
  }

  void _describe(BuildContext context, String reason, Order? order) => showAppBottomSheet<void>(
    context,
    title: reason,
    builder: (_) => _DescribeSheet(order: order),
  ).ignore();
}

/// Cancelar mientras el negocio no empezó a prepararlo. Después, solo por soporte.
class _CancelOrderButton extends ConsumerStatefulWidget {
  const _CancelOrderButton({required this.order});

  final Order order;

  @override
  ConsumerState<_CancelOrderButton> createState() => _CancelOrderButtonState();
}

class _CancelOrderButtonState extends ConsumerState<_CancelOrderButton> {
  var _cancelling = false;

  Future<void> _cancel() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Cancelar tu pedido?',
      message: '${widget.order.store.name} todavía no empezó a prepararlo. No se te cobrará nada.',
      confirmLabel: 'Sí, cancelar',
      cancelLabel: 'No, mantenerlo',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _cancelling = true);
    final result = await ref.read(ordersRepositoryProvider).cancel(widget.order.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    switch (result) {
      case Ok():
        ref
          ..invalidate(orderWatchProvider(widget.order.id))
          ..invalidate(ordersHistoryProvider);
        if (ref.read(activeOrderIdProvider).value == widget.order.id) {
          ref.read(activeOrderIdProvider.notifier).clear();
        }
        AppToast.show(context, 'Cancelamos tu pedido. No se te cobró nada.', kind: AppToastKind.success);
      case Err(:final failure):
        // P. ej. el negocio lo empezó a preparar hace un momento.
        ref.invalidate(orderWatchProvider(widget.order.id));
        AppToast.show(context, failure.message, kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) => AppButton.danger(
    label: 'Cancelar pedido',
    icon: Icons.cancel_outlined,
    loading: _cancelling,
    onPressed: _cancelling ? null : _cancel,
  );
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (order.status) {
      OrderStatus.delivered => 'Entregado',
      OrderStatus.cancelled => 'Cancelado',
      _ => 'En curso',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          AppAvatar(imageUrl: order.store.logoUrl, variant: AppAvatarVariant.store, size: 48, fallbackIcon: Icons.storefront_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.store.name} · ${order.code}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.relativeDay(order.placedAt)} · ${Formatters.money(order.total)} · $status',
                  style: theme.textTheme.bodySmall?.copyWith(fontFeatures: AppTypography.tabularFigures),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja para contar qué pasó. Por ahora el envío es local (sin backend de soporte).
class _DescribeSheet extends StatefulWidget {
  const _DescribeSheet({this.order});

  final Order? order;

  @override
  State<_DescribeSheet> createState() => _DescribeSheetState();
}

class _DescribeSheetState extends State<_DescribeSheet> {
  final _text = TextEditingController();
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future<void>.delayed(AppMotion.move);
    if (!mounted) return;
    Navigator.of(context).pop();
    AppToast.show(context, 'Listo. Te escribimos en menos de 10 minutos.', kind: AppToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order == null ? 'Cuéntanos qué pasó.' : 'Cuéntanos qué pasó con tu pedido ${order.code} de ${order.store.name}.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Ej.: faltó la gaseosa del combo'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: 'Enviar', loading: _sending, onPressed: _text.text.trim().isEmpty ? null : _send),
          ],
        ),
      ),
    );
  }
}
