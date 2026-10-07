import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barra inferior clásica, con ícono y etiqueta siempre visibles. "Bolsa" no es
/// una rama: abre la bolsa. [index] es de rama (0 inicio, 1 buscar, 2 pedidos, 3 tú).
class AppNavigationDock extends StatelessWidget {
  const AppNavigationDock({
    required this.index,
    required this.onSelected,
    this.bagCount = 0,
    this.bagPulse = 0,
    this.onBag,
    this.liveOrder = false,
    this.avatar,
    super.key,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final int bagCount;

  /// Incrementarlo hace saltar el contador (al recibir un producto).
  final int bagPulse;
  final VoidCallback? onBag;

  /// Hay un pedido en curso: "Pedidos" lleva un punto.
  final bool liveOrder;

  /// Avatar del usuario en "Tú" (si no, un ícono).
  final Widget? avatar;

  /// Destino del producto que vuela a la bolsa (ver `flyToPurchaseBar`).
  static final GlobalKey bagKey = GlobalKey(debugLabel: 'bag-tab');

  static const indicatorShape = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(16),
    bottomLeft: Radius.circular(5),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? scheme.surface : AppColors.blanco,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  _Tab(
                    label: 'Inicio',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    selected: index == 0,
                    onTap: () => onSelected(0),
                  ),
                  _Tab(
                    label: 'Buscar',
                    icon: Icons.search_rounded,
                    selectedIcon: Icons.search_rounded,
                    selected: index == 1,
                    onTap: () => onSelected(1),
                  ),
                  _Tab(
                    label: 'Pedidos',
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    selected: index == 2,
                    onTap: () => onSelected(2),
                    semanticsHint: liveOrder ? '1 en curso' : null,
                    marker: liveOrder ? const _Dot() : null,
                  ),
                  _Tab(
                    key: bagKey,
                    label: 'Bolsa',
                    icon: Icons.shopping_bag_outlined,
                    selectedIcon: Icons.shopping_bag_rounded,
                    selected: false,
                    onTap: onBag ?? () {},
                    semanticsHint: bagCount > 0 ? '$bagCount ${bagCount == 1 ? 'producto' : 'productos'}' : null,
                    marker: bagCount > 0 ? _Count(count: bagCount, pulse: bagPulse) : null,
                  ),
                  _Tab(
                    label: 'Tú',
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    selected: index == 3,
                    onTap: () => onSelected(3),
                    custom: avatar,
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.semanticsHint,
    this.marker,
    this.custom,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsHint;
  final Widget? marker;
  final Widget? custom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticsHint == null ? label : '$label, $semanticsHint',
        onTap: onTap,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: AppRadius.tile,
            onTap: () {
              HapticFeedback.selectionClick().ignore();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                    curve: AppMotion.arrive,
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected ? scheme.primaryContainer : Colors.transparent,
                      borderRadius: AppNavigationDock.indicatorShape,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        custom ?? Icon(selected ? selectedIcon : icon, size: 24, color: color),
                        if (marker != null) Positioned(top: -2, left: 32, child: marker!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
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

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
    ),
  );
}

/// Contador de la bolsa; salta cuando [pulse] cambia.
class _Count extends StatelessWidget {
  const _Count({required this.count, required this.pulse});

  final int count;
  final int pulse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onPrimary, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1),
      ),
    );
    if (reduceMotionOf(context)) return badge;
    return TweenAnimationBuilder<double>(
      key: ValueKey(pulse),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.story,
      builder: (context, t, child) => Transform.scale(scale: 1 + 0.35 * (1 - (2 * t - 1).abs()), child: child),
      child: badge,
    );
  }
}
