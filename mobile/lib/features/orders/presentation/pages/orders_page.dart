import 'package:apamuy/core/time/clock_provider.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/presentation/order_status_labels.dart';
import 'package:apamuy/features/orders/presentation/pages/order_help_page.dart';
import 'package:apamuy/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
import 'package:apamuy/features/orders/presentation/widgets/order_progress_rail.dart';
import 'package:apamuy/features/orders/presentation/widgets/rating_sheet.dart';
import 'package:apamuy/features/orders/presentation/widgets/store_thumb.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({this.onExplore, this.onOpenStore, super.key});

  static const name = 'orders';

  final VoidCallback? onExplore;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(ordersHistoryProvider);
    void retry() => ref.invalidate(ordersHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersHistoryProvider.future),
        // AsyncValueView pinta su error sin scroll; aquí debe poder arrastrarse
        // para reintentar, así que el error sin datos se resuelve antes.
        child: history is AsyncError<OrderLists> && !history.hasValue
            ? _Pullable(child: AppEmptyState.fromError(history.error, onRetry: retry))
            : AsyncValueView(
                value: history,
                onRetry: retry,
                loading: const _OrdersSkeleton(),
                isEmpty: (orders) => orders.isEmpty,
                empty: _Pullable(
                  child: AppEmptyState(
                    scene: AppEmptyArt.receipt,
                    title: 'Aún no tienes pedidos',
                    message: 'Cuando pidas algo, aquí podrás seguirlo y volver a pedirlo en un toque.',
                    actionLabel: onExplore == null ? null : 'Ver qué hay cerca',
                    onAction: onExplore,
                  ),
                ),
                data: (lists) => _OrdersList(lists: lists, onOpenStore: onOpenStore),
              ),
      ),
    );
  }
}

/// Un estado de pantalla completa que se puede arrastrar para refrescar.
class _Pullable extends StatelessWidget {
  const _Pullable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.lists, this.onOpenStore});

  final OrderLists lists;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final active = lists.active;
    final past = lists.past;
    final animate = entranceWindowOpen(lists);
    // Activos, luego (si hay anteriores) título, anteriores y el enlace de ayuda.
    final count = active.length + (past.isEmpty ? 0 : past.length + 2);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, AppSpacing.xxl),
      itemCount: count,
      itemBuilder: (context, i) {
        Widget enter(Widget child) => FadeSlideIn.staggered(index: i, enabled: animate, child: child);
        if (i < active.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
            child: enter(_ActiveOrderCard(order: active[i])),
          );
        }
        final j = i - active.length;
        if (j == 0) {
          return Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, active.isEmpty ? 0 : AppSpacing.md, AppSpacing.gutter, AppSpacing.xs),
            child: Semantics(header: true, child: Text('ANTERIORES', style: AppTypography.eyebrow(context))),
          );
        }
        if (j <= past.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
            child: enter(_PastOrderCard(order: past[j - 1], onOpenStore: onOpenStore)),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, 0),
          child: AppGroupedRow.link(
            icon: Icons.help_outline_rounded,
            title: '¿Problema con un pedido anterior?',
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            onTap: () => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': past.first.id}),
          ),
        );
      },
    );
  }
}

/// El pedido en curso como boleta: quién lo prepara, cuánto falta, la barra de
/// tramos y qué está pasando. Toda la boleta abre el seguimiento.
class _ActiveOrderCard extends ConsumerWidget {
  const _ActiveOrderCard({required this.order});

  final Order order;

  static const _stages = ['Confirmado', 'Preparando', 'En camino', 'Entregado'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(orderWatchProvider(order.id)).value ?? order;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minutes = live.minutesLeft(ref.watch(clockProvider).value ?? DateTime.now());
    final eta = live.estimatedArrival;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures);
    void track() => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': live.id});

    return Semantics(
      button: true,
      label: '${live.store.name}. ${live.headline}${minutes == null ? '' : '. Llega en $minutes minutos'}. Ver seguimiento',
      excludeSemantics: true,
      child: PressableScale(
        child: GestureDetector(
          onTap: track,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TicketEdge(top: true),
              TicketSection(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        StoreThumb(url: live.store.logoUrl, size: 40, background: context.apamuy.raised),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(live.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                [live.code, if (eta != null) 'Llega a las ${Formatters.clock(eta)}'].join(' · '),
                                style: muted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (minutes != null)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '$minutes', style: AppTypography.price(context, size: 28).copyWith(height: 1)),
                                TextSpan(text: ' min', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        else
                          AppLiveTag(label: live.status.tag),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppStageBar(stages: _stages, current: OrderProgressRail.stageOf(live.status)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(live.headline, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              TicketSection(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.xs, AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Ver seguimiento', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                    Icon(Icons.chevron_right_rounded, color: scheme.primary),
                  ],
                ),
              ),
              const TicketEdge(top: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un pedido anterior: quién, cuándo, cuánto y qué llevaba, con su estado claro
/// y lo que se puede hacer (calificarlo si falta y volver a pedir).
class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({required this.order, this.onOpenStore});

  final Order order;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    final cancelled = order.status == OrderStatus.cancelled;
    final rating = order.rating;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures);
    final items = order.lines.map((l) => '${l.quantity}× ${l.name}').join(', ');

    return Material(
      color: apamuy.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id}),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoreThumb(url: order.store.logoUrl, size: 44, background: apamuy.raised),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${Formatters.relativeDay(order.placedAt)} · ${order.code}', style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    Formatters.money(order.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: AppTypography.tabularFigures,
                      color: cancelled ? scheme.onSurfaceVariant : null,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(items, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _StatusChip(order: order),
                  if (rating != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.star_rounded, size: 16, color: apamuy.rating),
                    Text(' $rating', style: theme.textTheme.labelMedium),
                  ],
                  const Spacer(),
                  if (order.status == OrderStatus.delivered && rating == null)
                    TextButton(
                      onPressed: () => showRatingSheet(context, order),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Calificar'),
                    ),
                  if (onOpenStore != null) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    AppButton.secondary(
                      label: 'Volver a pedir',
                      semanticLabel: 'Volver a pedir en ${order.store.name}',
                      size: AppButtonSize.sm,
                      expand: false,
                      onPressed: () => onOpenStore!(order.store.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Entregado" en verde o "Cancelado" en rojo, con su ícono.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final apamuy = context.apamuy;
    final cancelled = order.status == OrderStatus.cancelled;
    final color = cancelled ? apamuy.danger : apamuy.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.button),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cancelled ? Icons.cancel_rounded : Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(order.status.summaryLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) => Skeleton(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
      children: [
        const SkeletonBox(height: 116, borderRadius: AppRadius.card),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(width: 90, height: 12),
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                SkeletonBox(width: 48, height: 48, borderRadius: AppRadius.tile),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: SkeletonLines()),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 72, height: 36, borderRadius: AppRadius.button),
              ],
            ),
          ),
      ],
    ),
  );
}
