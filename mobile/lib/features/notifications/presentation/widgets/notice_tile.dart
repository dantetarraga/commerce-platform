import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/notifications/domain/notice.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "7:03 pm" si es de hoy; "Ayer, 7:03 pm" o la fecha si no.
String noticeTime(DateTime at, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final sameDay = at.year == today.year && at.month == today.month && at.day == today.day;
  return sameDay ? Formatters.clock(at) : Formatters.relativeDay(at, now: now);
}

/// Un aviso: ícono (terracota para pedidos, hierba para ofertas), título con
/// la hora y cuerpo. Sin leer, la fila va tintada y con el punto de la marca.
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
    final apamuy = context.apamuy;
    final order = notice.kind.isOrder;
    final time = noticeTime(notice.at);
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
                        color: order ? scheme.primaryContainer : apamuy.accentSoft,
                        borderRadius: AppRadius.button,
                      ),
                      child: Icon(_icon, size: 22, color: order ? scheme.primary : apamuy.accent),
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
                                  fontFeatures: AppTypography.tabularFigures,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(notice.body, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (!order) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text('Ver negocio', style: theme.textTheme.labelMedium?.copyWith(color: apamuy.accent)),
                          ],
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: unread ? 1 : 0,
                      duration: quick,
                      child: const Padding(padding: EdgeInsets.only(left: AppSpacing.xs, top: 4), child: NoticeUnreadDot()),
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

/// El punto del pedido de la marca: lo que no se ha leído.
class NoticeUnreadDot extends StatelessWidget {
  const NoticeUnreadDot({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: context.apamuy.accent, shape: BoxShape.circle),
  );
}
