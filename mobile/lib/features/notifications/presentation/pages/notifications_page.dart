import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:chaski/features/orders/orders_customer.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Filter {
  all('Todos'),
  orders('Pedidos'),
  offers('Ofertas');

  const _Filter(this.label);

  final String label;

  bool accepts(Notice n) => switch (this) {
    all => true,
    orders => n.kind.isOrder,
    offers => !n.kind.isOrder,
  };
}

/// Centro de avisos. El pedido en curso va arriba como un solo hilo (sus
/// avisos, anudados); el resto se agrupa por HOY / AYER / ANTES y se puede
/// filtrar entre pedidos y ofertas.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  static const name = 'notifications';

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  _Filter _filter = _Filter.all;

  void _open(Notice notice) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notices = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNoticesCountProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          AppButton.ghost(
            label: 'Marcar leídos',
            size: AppButtonSize.sm,
            onPressed: unread == 0 ? null : () => ref.read(notificationsProvider.notifier).markAllRead(),
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
            final thread = _filter == _Filter.offers ? const <Notice>[] : activeOrderThread(list);
            final inThread = {for (final n in thread) n.id};
            final rest = list.where((n) => !inThread.contains(n.id) && _filter.accepts(n)).toList();
            final groups = groupNotices(rest, DateTime.now());
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxs),
                  child: Semantics(header: true, child: Text('Avisos', style: theme.textTheme.headlineLarge)),
                ),
                Padding(
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
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.screen,
                  child: Row(
                    children: [
                      for (final f in _Filter.values) ...[
                        AppChip(
                          label: f.label,
                          variant: AppChipVariant.choice,
                          selected: f == _filter,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
                if (thread.isNotEmpty) ...[
                  _groupTitle(context, 'EN CURSO'),
                  Padding(
                    padding: AppSpacing.screen,
                    child: OrderThreadCard(notices: thread, onTap: () => _open(thread.last)),
                  ),
                ],
                for (final MapEntry(key: day, value: items) in groups.entries) ...[
                  _groupTitle(context, day.label),
                  for (final n in items) NoticeTile(notice: n, onTap: () => _open(n)),
                ],
                if (thread.isEmpty && rest.isEmpty)
                  AppEmptyState(
                    compact: true,
                    scene: _filter == _Filter.offers ? AppEmptyArt.emptyBag : AppEmptyArt.receipt,
                    title: _filter == _Filter.offers ? 'Sin ofertas por ahora' : 'Sin avisos de pedidos',
                    message: 'Te avisamos aquí apenas haya algo nuevo.',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _groupTitle(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xs),
  child: Semantics(header: true, child: Text(label, style: AppTypography.eyebrow(context))),
);

/// "7:03" si es de hoy; "Ayer, 7:03" o la fecha si no.
String _time(DateTime at) {
  final label = Formatters.relativeDay(at);
  return label.startsWith('Hoy, ') ? label.substring(5) : label;
}

/// El pedido en curso: sus avisos anudados en un hilo, el último latiendo.
class OrderThreadCard extends StatelessWidget {
  const OrderThreadCard({required this.notices, required this.onTap, super.key});

  /// Del más antiguo al más reciente.
  final List<Notice> notices;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = notices.last;
    final unread = notices.any((n) => !n.read);

    return Semantics(
      button: true,
      label: '${unread ? 'Sin leer. ' : ''}Pedido en curso. ${latest.title}. ${latest.body}',
      hint: 'Abre el seguimiento',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppQuipu(
                    dense: true,
                    steps: [
                      for (final n in notices)
                        QuipuStep(
                          title: n.title,
                          subtitle: identical(n, latest) ? n.body : null,
                          trailing: _time(n.at),
                          knot: identical(n, latest) ? QuipuKnot.current : QuipuKnot.done,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (unread) ...[
                        const _UnreadDot(),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Novedades', style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
                      ],
                      const Spacer(),
                      Text('Ver seguimiento', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                      Icon(Icons.chevron_right_rounded, color: scheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un aviso: ícono con su esquina de salida (terracota para pedidos, hierba
/// para ofertas), título con la hora a la derecha y cuerpo. Sin leer, la fila
/// va tintada y con el punto de la marca.
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
    final time = _time(notice.at);
    final unread = !notice.read;
    final quick = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;

    return Semantics(
      button: true,
      label: '${unread ? 'Sin leer. ' : ''}${notice.title}. ${notice.body}. $time',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 2),
        child: AnimatedContainer(
          duration: quick,
          decoration: BoxDecoration(
            color: unread ? scheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: AppRadius.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: order ? scheme.primaryContainer : chaski.accentSoft,
                        borderRadius: AppRadius.button,
                      ),
                      child: Icon(_icon, size: 22, color: order ? scheme.primary : chaski.accent),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notice.title,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                time,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: unread ? scheme.primary : scheme.onSurfaceVariant,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(notice.body, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (!order) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text('Ver negocio', style: theme.textTheme.labelMedium?.copyWith(color: chaski.accent)),
                          ],
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: unread ? 1 : 0,
                      duration: quick,
                      child: const Padding(padding: EdgeInsets.only(left: AppSpacing.xs, top: 4), child: _UnreadDot()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El punto verde del pedido de la marca: marca lo que no se ha leído.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: context.chaski.accent, shape: BoxShape.circle),
  );
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
