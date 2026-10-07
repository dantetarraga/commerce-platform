import 'package:chaski/features/notifications/domain/notice.dart';
import 'package:chaski/features/notifications/presentation/widgets/notice_tile.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

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
      hint: 'Abre el seguimiento',
      child: AppTapSurface(
        semanticLabel: '${unread ? 'Sin leer. ' : ''}Pedido en curso. ${latest.title}. ${latest.body}',
        color: scheme.primaryContainer,
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
                      trailing: noticeTime(n.at),
                      knot: identical(n, latest) ? QuipuKnot.current : QuipuKnot.done,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (unread) ...[
                    const NoticeUnreadDot(),
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
    );
  }
}
