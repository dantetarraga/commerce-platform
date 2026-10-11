import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/presentation/order_status_labels.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
import 'package:apamuy/features/orders/presentation/widgets/order_progress_rail.dart';
import 'package:apamuy/features/orders/presentation/widgets/store_thumb.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "¿Algún problema con tu pedido?": motivos concretos y contacto con soporte.
class OrderHelpPage extends ConsumerWidget {
  const OrderHelpPage({required this.orderId, super.key});

  static const name = 'orderHelp';

  final String orderId;

  /// Los motivos dependen de en qué va el pedido: en curso preocupa la demora o
  /// la dirección; entregado, lo que llegó.
  static List<(IconData, String)> _reasonsFor(Order? order) => switch (order?.status) {
    OrderStatus.delivered => const [
      (Icons.shopping_bag_outlined, 'Falta un producto'),
      (Icons.close_rounded, 'Llegó dañado o equivocado'),
      (Icons.ac_unit_rounded, 'Llegó frío'),
      (Icons.credit_card_rounded, 'Me cobraron mal'),
      (Icons.more_horiz_rounded, 'Otro'),
    ],
    OrderStatus.cancelled => const [
      (Icons.credit_card_rounded, 'Me cobraron igual'),
      (Icons.more_horiz_rounded, 'Otro'),
    ],
    null => const [(Icons.more_horiz_rounded, 'Otro')],
    _ => const [
      (Icons.schedule_rounded, 'Tarda más de lo que dice'),
      (Icons.location_on_outlined, 'Quiero cambiar la dirección'),
      (Icons.edit_note_rounded, 'Quiero cambiar algo del pedido'),
      (Icons.more_horiz_rounded, 'Otro'),
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              AsyncError(:final error) => AppInlineNotice.fromError(error, onRetry: () => ref.invalidate(orderWatchProvider(orderId))),
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
          AppGroupedCard(
            children: [
              for (final (icon, reason) in _reasonsFor(order.value))
                AppGroupedRow(icon: icon, title: reason, onTap: () => _describe(context, reason, order.value)),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          _SupportCard(onWrite: () => _describe(context, 'Escribir a soporte', order.value)),
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

/// El pedido como talón de boleta: quién, cuándo, cuánto y en qué va.
class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final Order order;

  static const _stages = ['Confirmado', 'Preparando', 'En camino', 'Entregado'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StoreThumb(url: order.store.logoUrl, background: context.apamuy.raised),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.store.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${order.code} · ${Formatters.relativeDay(order.placedAt)} · ${order.status.summaryLabel}', style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(Formatters.money(order.total), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppTypography.tabularFigures)),
                ],
              ),
              if (order.isActive) ...[
                const SizedBox(height: AppSpacing.md),
                AppStageBar(stages: _stages, current: OrderProgressRail.stageOf(order.status)),
              ],
            ],
          ),
        ),
        const TicketEdge(top: false),
      ],
    );
  }
}

/// Soporte con cara: en línea, cuánto tarda en responder y el botón para escribir.
class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = context.apamuy.success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.exit(14, cut: 4)),
                child: Icon(Icons.support_agent_rounded, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habla con nosotros', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: success),
                        const SizedBox(width: 6),
                        Flexible(child: Text('Respondemos en menos de 10 minutos, de 7 am a 11 pm.', style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Escribir a soporte', icon: Icons.chat_bubble_outline_rounded, onPressed: onWrite),
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
            AppInput(
              label: 'Qué pasó',
              controller: _text,
              variant: AppInputVariant.note,
              hint: 'Ej.: faltó la gaseosa del combo',
              autofocus: true,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListenableBuilder(
              listenable: _text,
              builder: (context, _) => AppButton(label: 'Enviar', loading: _sending, onPressed: _text.text.trim().isEmpty ? null : _send),
            ),
          ],
        ),
      ),
    );
  }
}
