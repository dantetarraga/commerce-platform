import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:chaski/features/notifications/presentation/widgets/notice_tile.dart';
import 'package:chaski/features/notifications/presentation/widgets/order_thread_card.dart';
import 'package:chaski/features/orders/orders_customer.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Centro de avisos: el pedido en curso arriba como un solo hilo; el resto,
/// por HOY / AYER / ANTES y filtrable entre pedidos y ofertas.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const name = 'notifications';

  void _open(BuildContext context, WidgetRef ref, Notice notice) {
    if (notice.storeId case final storeId?) {
      context.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': storeId}).ignore();
      return;
    }
    // Los avisos de prueba no traen pedido: usan el que está en curso.
    final orderId = notice.orderId ?? ref.read(activeOrderIdProvider).value;
    if (notice.kind.isOrder && notice.kind != NoticeKind.delivered && orderId != null) {
      context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': orderId}).ignore();
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(notificationsProvider.notifier).markAllRead();
    if (failure != null && context.mounted) {
      AppToast.show(context, 'No pudimos marcarlos como leídos. Inténtalo otra vez.', kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(noticeFeedProvider);
    final unread = ref.watch(unreadNoticesCountProvider);
    final hasNotices = ref.watch(notificationsProvider.select((s) => s.value?.isNotEmpty ?? false));

    return Scaffold(
      appBar: AppBar(
        actions: [
          AppButton.ghost(
            label: 'Marcar leídos',
            size: AppButtonSize.sm,
            onPressed: unread == 0 ? null : () => _markAllRead(context, ref),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncValueView(
          value: feed,
          onRetry: () => ref.invalidate(notificationsProvider),
          loading: const Skeleton(child: _NoticesSkeleton()),
          isEmpty: (_) => !hasNotices,
          empty: const AppEmptyState(
            title: 'Todo tranquilo por aquí',
            message: 'Cuando tu pedido avance o haya una oferta cerca, te avisamos aquí.',
          ),
          data: (feed) => _NoticeList(feed: feed, unread: unread, onOpen: (n) => _open(context, ref, n)),
        ),
      ),
    );
  }
}

/// Encabezados, hilo y avisos aplanados para construirlos de a uno (lista lazy).
sealed class _Item {
  const _Item();
}

class _Header extends _Item {
  const _Header(this.label);

  final String label;
}

class _Thread extends _Item {
  const _Thread(this.notices);

  final List<Notice> notices;
}

class _Row extends _Item {
  const _Row(this.notice);

  final Notice notice;
}

class _Empty extends _Item {
  const _Empty();
}

class _NoticeList extends ConsumerWidget {
  const _NoticeList({required this.feed, required this.unread, required this.onOpen});

  final NoticeFeed feed;
  final int unread;
  final ValueChanged<Notice> onOpen;

  /// Título, contador y filtros van antes de los avisos.
  static const _leading = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(noticeFilterSelectionProvider);
    final items = <_Item>[
      if (feed.thread.isNotEmpty) ...[const _Header('EN CURSO'), _Thread(feed.thread)],
      for (final MapEntry(key: day, value: notices) in feed.groups.entries) ...[
        _Header(day.label),
        for (final n in notices) _Row(n),
      ],
      if (feed.thread.isEmpty && feed.groups.isEmpty) const _Empty(),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _leading + items.length,
      itemBuilder: (context, index) => switch (index) {
        0 => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxs),
          child: Semantics(header: true, child: Text('Avisos', style: theme.textTheme.headlineLarge)),
        ),
        1 => Padding(
          padding: AppSpacing.screen,
          child: Text(
            switch (unread) {
              0 => 'Estás al día.',
              1 => '1 aviso sin leer',
              _ => '$unread avisos sin leer',
            },
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        2 => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
          child: Row(
            children: [
              for (final f in NoticeFilter.values) ...[
                AppChip(
                  label: f.label,
                  variant: AppChipVariant.choice,
                  selected: f == filter,
                  onTap: () => ref.read(noticeFilterSelectionProvider.notifier).select(f),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        _ => switch (items[index - _leading]) {
          _Header(:final label) => AppSectionHeader.eyebrow(label),
          _Thread(:final notices) => Padding(
            padding: AppSpacing.screen,
            child: OrderThreadCard(notices: notices, onTap: () => onOpen(notices.last)),
          ),
          _Row(:final notice) => NoticeTile(notice: notice, onTap: () => onOpen(notice)),
          _Empty() => AppEmptyState(
            compact: true,
            scene: filter == NoticeFilter.offers ? AppEmptyArt.emptyBag : AppEmptyArt.receipt,
            title: filter == NoticeFilter.offers ? 'Sin ofertas por ahora' : 'Sin avisos de pedidos',
            message: 'Te avisamos aquí apenas haya algo nuevo.',
          ),
        },
      },
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
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 140, height: 32)),
      ),
      const SizedBox(height: AppSpacing.lg),
      const Padding(padding: AppSpacing.screen, child: SkeletonBox.signature(height: 150)),
      for (var i = 0; i < 4; i++)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
          child: Row(
            children: [
              SkeletonBox(width: 44, height: 44, borderRadius: AppRadius.button),
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
