import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pestañas en píldora conectadas al [TabController] más cercano.
class PartnerPillTabs extends StatelessWidget implements PreferredSizeWidget {
  const PartnerPillTabs({required this.labels, super.key});

  final List<String> labels;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.minTouch + 16);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
        child: Row(
          children: [
            for (final (i, label) in labels.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Semantics(
                selected: controller.index == i,
                button: true,
                child: Material(
                  color: controller.index == i ? scheme.primary : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                    side: BorderSide(color: controller.index == i ? scheme.primary : scheme.outlineVariant, width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.button,
                    onTap: () => controller.animateTo(i),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: AppSpacing.minTouch, minWidth: 64),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: controller.index == i ? scheme.onPrimary : scheme.onSurface,
                          fontWeight: controller.index == i ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
