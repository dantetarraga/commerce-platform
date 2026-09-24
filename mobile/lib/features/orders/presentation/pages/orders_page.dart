import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/pages/order_help_page.dart';
import 'package:chaski/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/features/orders/presentation/widgets/order_bits.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Historial de pedidos (dentro de "Tú"): el que va en camino arriba y los
/// anteriores como filas con "Repetir".
class OrdersPage extends ConsumerWidget {
  const OrdersPage({this.onExplore, this.onOpenStore, super.key});

  static const name = 'orders';

  /// La app decide a dónde llevan estas acciones (el feature no conoce rutas ajenas).
  final VoidCallback? onExplore;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(ordersHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersHistoryProvider.future),
        child: history is AsyncError<List<Order>> && !history.hasValue
            ? orderLoadError(history.error, what: 'tus pedidos', onRetry: () => ref.invalidate(ordersHistoryProvider))
            : AsyncValueView(
                value: history,
                onRetry: () => ref.invalidate(ordersHistoryProvider),
                loading: const _OrdersSkeleton(),
                isEmpty: (orders) => orders.isEmpty,
                empty: AppEmptyState(
                  scene: ThreadScene.receipt,
                  title: 'Aún no tienes pedidos',
                  message: 'Cuando pidas algo, aquí podrás seguirlo y volver a pedirlo en un toque.',
                  actionLabel: onExplore == null ? null : 'Ver qué hay cerca',
                  onAction: onExplore,
                ),
                data: (orders) => _OrdersList(orders: orders, onOpenStore: onOpenStore),
              ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, this.onOpenStore});

  final List<Order> orders;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => o.isActive).toList();
    final past = orders.where((o) => !o.isActive).toList();
    final animate = entranceWindowOpen(orders);
    var index = 0;
    Widget enter(Widget child) => FadeSlideIn.staggered(index: index++, enabled: animate, child: child);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, AppSpacing.xxl),
      children: [
        for (final order in active)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
            child: enter(_ActiveOrderCard(order: order)),
          ),
        if (past.isNotEmpty) ...[
          SizedBox(height: active.isEmpty ? 0 : AppSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
            child: Semantics(header: true, child: Text('ANTERIORES', style: AppTypography.eyebrow(context))),
          ),
          for (final order in past) enter(_PastOrderRow(order: order, onOpenStore: onOpenStore)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _HelpLink(orderId: past.first.id),
          ),
        ],
      ],
    );
  }
}

/// Pedido en curso: tarjeta cobalto suave con su estado vivo.
class _ActiveOrderCard extends ConsumerWidget {
  const _ActiveOrderCard({required this.order});

  final Order order;

  /// Tramos de la barra: confirmado · preparado · en camino · entregado.
  static int _stage(OrderStatus s) => switch (s) {
    OrderStatus.received => 0,
    OrderStatus.confirmed => 1,
    OrderStatus.preparing || OrderStatus.ready => 2,
    OrderStatus.courierAssigned || OrderStatus.onTheWay => 3,
    OrderStatus.delivered || OrderStatus.cancelled => 4,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(orderWatchProvider(order.id)).value ?? order;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minutes = live.minutesLeft(DateTime.now());
    final stage = _stage(live.status);
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
                    _StoreLogo(url: live.store.logoUrl, size: 36, background: scheme.surface),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(live.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    LiveTag(label: minutes == null ? statusTag(live.status) : '$minutes MIN'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: AnimatedContainer(
                          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < stage ? context.chaski.thread : scheme.surfaceContainerHighest,
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
                      child: Text(
                        live.headline,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
    final status = order.status == OrderStatus.cancelled ? 'Cancelado' : 'Entregado';
    return InkWell(
      onTap: () => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
        child: Row(
          children: [
            _StoreLogo(url: order.store.logoUrl, size: 48, background: context.chaski.raised),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.store.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.relativeDay(order.placedAt)} · ${Formatters.money(order.total)} · $status',
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

/// Logo del negocio en mosaico (gris si no hay foto).
class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.url, required this.size, required this.background});

  final String? url;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    if (url != null) return AppAvatar(imageUrl: url, variant: AppAvatarVariant.store, size: size, fallbackIcon: Icons.storefront_rounded);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: AppRadius.tile),
        child: Icon(Icons.storefront_rounded, size: size * 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HelpLink extends StatelessWidget {
  const _HelpLink({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: AppRadius.tile,
        onTap: () => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': orderId}),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.help_outline_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('¿Problema con un pedido anterior?', style: theme.textTheme.labelLarge)),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
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
