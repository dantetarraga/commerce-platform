import 'package:apamuy/features/stores/domain/entities/store_menu.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Fila fija de chips con las secciones de la carta.
class MenuSectionTabsDelegate extends SliverPersistentHeaderDelegate {
  MenuSectionTabsDelegate({required this.sections, required this.active, required this.onSelected});

  final List<MenuSection> sections;
  final ValueListenable<String?> active;
  final ValueChanged<String> onSelected;

  static const height = 64.0;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: overlapsContent ? AppShadows.soft(theme.brightness) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _SectionTabs(sections: sections, active: active, onSelected: onSelected),
      ),
    );
  }

  @override
  bool shouldRebuild(MenuSectionTabsDelegate oldDelegate) => oldDelegate.sections != sections || oldDelegate.active != active;
}

/// El chip activo se centra solo en la fila.
class _SectionTabs extends StatefulWidget {
  const _SectionTabs({required this.sections, required this.active, required this.onSelected});

  final List<MenuSection> sections;
  final ValueListenable<String?> active;
  final ValueChanged<String> onSelected;

  @override
  State<_SectionTabs> createState() => _SectionTabsState();
}

class _SectionTabsState extends State<_SectionTabs> {
  final _scroll = ScrollController();
  final _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_revealActive);
  }

  @override
  void didUpdateWidget(_SectionTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      oldWidget.active.removeListener(_revealActive);
      widget.active.addListener(_revealActive);
    }
  }

  @override
  void dispose() {
    widget.active.removeListener(_revealActive);
    _scroll.dispose();
    super.dispose();
  }

  void _revealActive() {
    final id = widget.active.value;
    final chip = id == null ? null : _chipKeys[id]?.currentContext?.findRenderObject();
    if (chip == null || !chip.attached || !_scroll.hasClients) return;
    final target = RenderAbstractViewport.of(
      chip,
    ).getOffsetToReveal(chip, 0.5).offset.clamp(0.0, _scroll.position.maxScrollExtent);
    if (reduceMotionOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: AppMotion.base, curve: AppMotion.arrive).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.active,
      builder: (context, active, _) => ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
        itemCount: widget.sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          return KeyedSubtree(
            key: _chipKeys.putIfAbsent(section.id, GlobalKey.new),
            child: AppChip(
              label: section.name,
              variant: AppChipVariant.choice,
              selected: section.id == active,
              onTap: () => widget.onSelected(section.id),
            ),
          );
        },
      ),
    );
  }
}
