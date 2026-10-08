import 'package:apamuy/core/time/clock_provider.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/presentation/order_status_labels.dart';
import 'package:apamuy/features/orders/presentation/pages/order_help_page.dart';
import 'package:apamuy/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
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
        if (j <= past.length) return enter(_PastOrderRow(order: past[j - 1], onOpenStore: onOpenStore));
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

class _ActiveOrderCard extends ConsumerWidget {
  const _ActiveOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(orderWatchProvider(order.id)).value ?? order;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minutes = live.minutesLeft(ref.watch(clockProvider).value ?? DateTime.now());
    final stage = live.status.stage;
    void track() => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': live.id});

    return Semantics(
      button: true,
      label: '${live.store.name}. ${live.headline}${minutes == null ? '' : '. Llega en $minutes minutos'}. Ver mapa',
      excludeSemantics: true,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: track,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StoreThumb(url: live.store.logoUrl, size: 36, background: scheme.surface),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(live.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppLiveTag(label: minutes == null ? live.status.tag : '$minutes MIN'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // Una barra por etapa antes de "terminado".
                    for (var i = 0; i < OrderStatus.stageCount - 1; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: AnimatedContainer(
                          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < stage ? context.apamuy.thread : scheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.all(AppRadius.pill),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(live.headline, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text('Ver mapa', style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastOrderRow extends StatelessWidget {
  const _PastOrderRow({required this.order, this.onOpenStore});

  final Order order;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
        child: Row(
          children: [
            StoreThumb(url: order.store.logoUrl, background: context.apamuy.raised),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.relativeDay(order.placedAt)} · ${Formatters.money(order.total)} · ${order.status.summaryLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(fontFeatures: AppTypography.tabularFigures),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onOpenStore != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AppButton.secondary(
                label: 'Repetir',
                semanticLabel: 'Repetir pedido de ${order.store.name}',
                size: AppButtonSize.sm,
                expand: false,
                onPressed: () => onOpenStore!(order.store.id),
              ),
            ],
          ],
        ),
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
