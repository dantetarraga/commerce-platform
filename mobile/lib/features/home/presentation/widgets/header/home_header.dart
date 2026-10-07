import 'dart:math' as math;

import 'package:chaski/core/config/city.dart';
import 'package:chaski/core/utils/text_scale.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/home/presentation/widgets/header/cover_art.dart';
import 'package:chaski/features/home/presentation/widgets/header/header_bars.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Portada del inicio: dirección y avisos, saludo, titular, la comida en
/// círculo y el buscador montado sobre el borde. Al hacer scroll se compacta en
/// una barra. Con un pedido en curso ([compactOnly]) solo muestra la barra.
class HomeHeader extends StatelessWidget {
  const HomeHeader({this.compactOnly = false, this.onHelp, super.key});

  final bool compactOnly;

  /// Con un pedido en curso, el botón "Ayuda" de la barra.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final extra = textScaleExtra(context);
    final min = top + (compactOnly ? 78 + extra * 3.5 : 68 + extra);
    final max = compactOnly ? min : top + 314 + extra * 11;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(minHeight: min, maxHeight: max, top: top, compactOnly: compactOnly, onHelp: onHelp),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.minHeight, required this.maxHeight, required this.top, required this.compactOnly, this.onHelp});

  final double minHeight;
  final double maxHeight;
  final double top;
  final bool compactOnly;
  final VoidCallback? onHelp;

  static const _searchOverlap = 27.0;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxHeight - minHeight;
    final t = compactOnly || range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final extent = math.max(minHeight, maxHeight - shrinkOffset);
    final heroHeight = compactOnly ? extent : math.max(minHeight, extent - _searchOverlap * (1 - t));
    final expanded = (1 - t * 1.8).clamp(0.0, 1.0);
    final compact = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: heroHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: compactOnly ? null : AppRadius.hero,
              boxShadow: t > 0.98 && !compactOnly ? AppShadows.soft(theme.brightness) : null,
            ),
          ),
        ),
        if (expanded > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroHeight,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Opacity(
                  opacity: expanded,
                  child: Padding(padding: EdgeInsets.only(top: top), child: const _ExpandedContent()),
                ),
              ),
            ),
          ),
        if (!compactOnly && expanded > 0)
          Positioned(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            bottom: 0,
            child: IgnorePointer(
              ignoring: expanded < 0.5,
              child: Opacity(
                opacity: expanded,
                child: AppSearchBar(
                  hints: const ['¿Qué te provoca hoy?', 'Busca comida, tiendas o productos', '¿Qué necesitamos llevarte?'],
                  onTap: () => context.goNamed(ExplorePage.name),
                ),
              ),
            ),
          ),
        if (compact > 0)
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: minHeight - top,
            child: IgnorePointer(
              ignoring: compact < 0.5,
              child: Opacity(
                opacity: compact,
                child: compactOnly ? HomeOrderBar(onHelp: onHelp) : const HomeCompactBar(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.minHeight != minHeight || old.maxHeight != maxHeight || old.top != top || old.compactOnly != compactOnly || old.onHelp != onHelp;
}

class _ExpandedContent extends ConsumerWidget {
  const _ExpandedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(authSessionProvider.select((s) => s.value?.firstName));
    final greeting = ref.watch(currentMomentProvider).greeting;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showArt = w >= 340 && !isLargeText(context);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showArt) HomeCoverArt(width: w),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: HomeAddressPill())),
                      SizedBox(width: 12),
                      HomeBell(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.only(right: showArt ? 150 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == null ? greeting : '$greeting, $name',
                          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Todo $cityName,\n'),
                                TextSpan(text: 'al toque.', style: TextStyle(color: scheme.primary)),
                              ],
                            ),
                            style: AppTypography.displayStyle(context, size: 40, weight: FontWeight.w800, height: 0.98, letterSpacing: -1),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            'Comida, bodega y encargos de tu barrio.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
