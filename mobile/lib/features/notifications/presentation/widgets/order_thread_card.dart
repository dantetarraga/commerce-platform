import 'package:apamuy/features/notifications/domain/notice.dart';
import 'package:apamuy/features/notifications/presentation/widgets/notice_tile.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// El pedido en curso como boleta: arriba el último aviso y la barra de tramos;
/// tras la perforación, los avisos anteriores con su hora.
class OrderThreadCard extends StatelessWidget {
  const OrderThreadCard({required this.notices, required this.onTap, super.key});

  /// Del más antiguo al más reciente.
  final List<Notice> notices;
  final VoidCallback onTap;

  static const _stages = ['Confirmado', 'Preparando', 'En camino', 'Entregado'];

  /// Tramo de la barra en el que va el pedido; `null` si se canceló.
  static int? _stageOf(NoticeKind kind) => switch (kind) {
    NoticeKind.orderConfirmed => 0,
    NoticeKind.preparing => 1,
    NoticeKind.courierAssigned || NoticeKind.courierNearby => 2,
    NoticeKind.delivered => 3,
    NoticeKind.orderCancelled || NoticeKind.promotion => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = notices.last;
    final earlier = notices.reversed.skip(1).toList();
    final unread = notices.any((n) => !n.read);
    final stage = _stageOf(latest.kind);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Semantics(
      button: true,
      hint: 'Abre el seguimiento',
      label: '${unread ? 'Sin leer. ' : ''}Pedido en curso. ${latest.title}. ${latest.body}',
      excludeSemantics: true,
      child: PressableScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TicketEdge(top: true),
              TicketSection(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                          child: Icon(noticeIcon(latest.kind), size: 20, color: scheme.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(latest.title, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(latest.body, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(noticeTime(latest.at), style: muted?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                            if (unread) ...[const SizedBox(height: AppSpacing.xs), const NoticeUnreadDot()],
                          ],
                        ),
                      ],
                    ),
                    if (stage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppStageBar(stages: _stages, current: stage),
                    ],
                  ],
                ),
              ),
              if (earlier.isNotEmpty) ...[
                const TicketPerforation(),
                TicketSection(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: [
                      for (final n in earlier)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: LeaderRow(
                            label: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                            value: Text(noticeTime(n.at), style: muted?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              TicketSection(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.xs, AppSpacing.sm),
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
