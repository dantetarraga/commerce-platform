import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Centro de avisos: pedido confirmado, preparando, repartidor cerca,
/// entregado y promociones. Agrupado por HOY / AYER / ANTES.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const name = 'notifications';

  void _open(BuildContext context, WidgetRef ref, Notice notice) {
    if (notice.storeId case final storeId?) {
      context.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': storeId}).ignore();
      return;
    }
    // Avisos de un pedido: llevan a su seguimiento (el aviso dice cuál; los
    // de prueba no lo traen y usan el pedido en curso).
    final orderId = notice.orderId ?? ref.read(activeOrderIdProvider).value;
    if (notice.kind.isOrder && notice.kind != NoticeKind.delivered && orderId != null) {
      context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': orderId}).ignore();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notices = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNoticesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          TextButton(
            onPressed: unread == 0 ? null : () => ref.read(notificationsProvider.notifier).markAllRead(),
            style: TextButton.styleFrom(minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch)),
            child: Text(
              'Marcar leídos',
              style: theme.textTheme.labelLarge?.copyWith(
                color: unread == 0 ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncValueView(
          value: notices,
          onRetry: () => ref.invalidate(notificationsProvider),
          loading: const Skeleton(child: _NoticesSkeleton()),
          isEmpty: (list) => list.isEmpty,
          empty: const AppEmptyState(
            title: 'Todo tranquilo por aquí',
            message: 'Cuando tu pedido avance o haya una oferta cerca, te avisamos aquí.',
          ),
          data: (list) {
            final groups = groupNotices(list, DateTime.now());
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                for (final MapEntry(key: day, value: items) in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xxs),
                    child: Semantics(header: true, child: Text(day.label, style: AppTypography.eyebrow(context))),
                  ),
                  for (final n in items) NoticeTile(notice: n, onTap: () => _open(context, ref, n)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un aviso: ícono en círculo (cobalto suave para pedidos, lima suave para
/// promos), título, cuerpo con la hora y punto cobalto si no se ha leído.
class NoticeTile extends StatelessWidget {
  const NoticeTile({required this.notice, required this.onTap, super.key});

  final Notice notice;
  final VoidCallback onTap;

  IconData get _icon => switch (notice.kind) {
    NoticeKind.orderConfirmed => Icons.check_rounded,
    NoticeKind.preparing => Icons.soup_kitchen_rounded,
    NoticeKind.courierAssigned => Icons.two_wheeler_rounded,
    NoticeKind.courierNearby => Icons.delivery_dining_rounded,
    NoticeKind.delivered => Icons.shopping_bag_rounded,
    NoticeKind.orderCancelled => Icons.cancel_outlined,
    NoticeKind.promotion => Icons.local_offer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final order = notice.kind.isOrder;
    final time = Formatters.relativeDay(notice.at);

    return Semantics(
      button: true,
      label: '${notice.read ? '' : 'Sin leer. '}${notice.title}. ${notice.body}. $time',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: order ? scheme.primaryContainer : chaski.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 22, color: order ? scheme.primary : chaski.onAccent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: notice.read ? FontWeight.w600 : FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text('${notice.body} · ${time.replaceFirst('Hoy, ', '')}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AnimatedOpacity(
                    opacity: notice.read ? 0 : 1,
                    duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticesSkeleton extends StatelessWidget {
  const _NoticesSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    children: [
      for (var i = 0; i < 5; i++)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
          child: Row(
            children: [
              SkeletonBox.circle(size: 44),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SkeletonBox(width: 180), SizedBox(height: 8), SkeletonBox(width: 240, height: 12)],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
