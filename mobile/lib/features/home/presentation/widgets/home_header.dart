import 'dart:math' as math;

import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Portada del inicio a todo el ancho: dirección y avisos dentro, saludo, titular, la
/// comida en círculo con el trazo y el buscador montado sobre el borde inferior. Al
/// hacer scroll se compacta en una barra con dirección, buscar y avisos.
///
/// Con un pedido en curso ([compactOnly]) solo muestra la barra: el seguimiento ocupa
/// la portada debajo.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({this.compactOnly = false, this.onHelp, super.key});

  final bool compactOnly;

  /// Con un pedido en curso, el botón "Ayuda" de la barra.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final extra = (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 24.0);
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

  final VoidCallback? onHelp;

  final double minHeight;
  final double maxHeight;
  final double top;
  final bool compactOnly;

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
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: heroHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: compactOnly ? null : AppRadius.hero,
              boxShadow: t > 0.98 && !compactOnly ? AppShadows.soft(Theme.of(context).brightness) : null,
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
                  child: Padding(
                    padding: EdgeInsets.only(top: top),
                    child: const _ExpandedContent(),
                  ),
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
                child: compactOnly ? _OrderBar(onHelp: onHelp) : const _CompactBar(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => old.minHeight != minHeight || old.maxHeight != maxHeight || old.top != top || old.compactOnly != compactOnly;
}

String _greeting(DateTime now) => switch (now.hour) {
  < 12 => 'Buenos días',
  < 19 => 'Buenas tardes',
  _ => 'Buenas noches',
};

class _ExpandedContent extends ConsumerWidget {
  const _ExpandedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(authSessionProvider).value?.firstName;
    final greeting = _greeting(DateTime.now());
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // La composición del lienzo está medida sobre 390 px: se ancla al borde derecho.
        final showArt = w >= 340 && MediaQuery.textScalerOf(context).scale(16) < 20;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showArt) ...[
              Positioned(left: 0, top: 0, width: w, height: 300, child: CustomPaint(painter: _RoutePainter(route: scheme.primary, start: context.chaski.accent, ring: scheme.primaryContainer))),
              _CoverArt(width: w),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Expanded(child: Align(alignment: Alignment.centerLeft, child: _AddressPill())), SizedBox(width: 12), _RoundBell()]),
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
                                const TextSpan(text: 'Todo Yauri,\n'),
                                TextSpan(text: 'al toque.', style: TextStyle(color: scheme.primary)),
                              ],
                            ),
                            style: TextStyle(
                              fontFamily: AppTypography.display,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 0.98,
                              letterSpacing: -1,
                              color: scheme.onSurface,
                            ),
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

/// Composición del lienzo, anclada al borde derecho: anillo punteado de 210, la comida
/// en un círculo de 164 que se sale de la pantalla, el pan en un círculo de 48, el nodo
/// de llegada y la etiqueta del negocio popular abierto sobre la foto.
class _CoverArt extends ConsumerWidget {
  const _CoverArt({required this.width});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hero = scheme.primaryContainer;
    final x = width - 390; // desplazamiento respecto del lienzo
    final nearest = ref.watch(storesProvider(sort: StoreSort.popular)).value?.items.where((s) => s.isOpenNow && s.coverUrl != null).firstOrNull;
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: 300,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: x + 228,
              top: 43,
              width: 210,
              height: 210,
              child: CustomPaint(painter: _DashedRing(color: scheme.primary.withValues(alpha: 0.35))),
            ),
            Positioned(
              left: x + 251,
              top: 66,
              child: const AppNetworkImage(url: 'assets/images/demo/grill.jpg', width: 164, height: 164, borderRadius: BorderRadius.all(Radius.circular(82))),
            ),
            Positioned(
              left: x + 222,
              top: 184,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: hero, width: 3)),
                child: const AppNetworkImage(url: 'assets/images/demo/bread.jpg', width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(21))),
              ),
            ),
            Positioned(
              left: x + 247,
              top: 62,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: context.chaski.accent, shape: BoxShape.circle, border: Border.all(color: hero, width: 4)),
              ),
            ),
            if (nearest != null)
              Positioned(
                right: 8,
                top: 222,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: const [BoxShadow(color: Color(0x382A1A14), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.moped_rounded, size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${nearest.name} · ${nearest.etaMinutes} min',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// El trazo punteado que sale abajo a la izquierda y llega al pan.
class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.route, required this.start, required this.ring});

  final Color route;
  final Color start;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final end = size.width - 168;
    double x(double canvasX) => 30 + (canvasX - 30) * (end - 30) / (222 - 30);
    final path = Path()
      ..moveTo(30, 250)
      ..cubicTo(x(110), 250, x(170), 242, end, 214);
    final metric = path.computeMetrics().first;
    final dot = Paint()..color = route;
    for (var d = 0.0; d < metric.length; d += 9) {
      final p = metric.getTangentForOffset(d)?.position;
      if (p != null) canvas.drawCircle(p, 1.6, dot);
    }
    canvas
      ..drawCircle(const Offset(30, 250), 7.5, Paint()..color = ring)
      ..drawCircle(const Offset(30, 250), 6, Paint()..color = start);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.route != route || old.start != start || old.ring != ring;
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side - 2, height: side - 2);
    // 44 trazos cortos: el mismo punteado del lienzo.
    const dashes = 44;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * 2 * math.pi / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}

/// "Entregar en · Jr. Tacna 248 ▾" en una píldora blanca; abre la hoja de direcciones.
class _AddressPill extends ConsumerWidget {
  const _AddressPill({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final address = ref.watch(selectedAddressProvider);
    final location = ref.watch(currentDeliveryLocationProvider);
    final label = address?.street ?? location.label;
    final icon = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: scheme.primary, borderRadius: AppRadius.button),
      child: Icon(address == null ? Icons.near_me_rounded : addressIcon(address.kind), size: 18, color: scheme.onPrimary),
    );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) Text('Entregar en', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: scheme.primary),
          ],
        ),
      ],
    );
    return Semantics(
      button: true,
      label: 'Entregar en $label. Cambiar dirección',
      excludeSemantics: true,
      onTap: () => showAddressPicker(context),
      child: Material(
        color: compact ? Colors.transparent : scheme.surface,
        borderRadius: AppRadius.tileExit,
        child: InkWell(
          borderRadius: AppRadius.tileExit,
          onTap: () => showAddressPicker(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
            child: Padding(
              padding: EdgeInsets.fromLTRB(compact ? 0 : 7, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Flexible(child: text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBell extends ConsumerWidget {
  const _RoundBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadNoticesCountProvider);
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
        onPressed: () => context.pushNamed(NotificationsPage.name),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(unread == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded, color: scheme.onSurface),
            if (unread > 0)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barra sobre el seguimiento: dirección en su píldora y ayuda con el pedido.
class _OrderBar extends StatelessWidget {
  const _OrderBar({this.onHelp});

  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 10, AppSpacing.gutter, 6),
      child: Row(
        children: [
          const Expanded(
            child: Align(alignment: Alignment.centerLeft, child: _AddressPill()),
          ),
          const SizedBox(width: 12),
          if (onHelp != null)
            Material(
              color: scheme.surface,
              borderRadius: AppRadius.tileExit,
              child: InkWell(
                borderRadius: AppRadius.tileExit,
                onTap: onHelp,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline_rounded, size: 20, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text('Ayuda', style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.md, 8),
      child: Row(
        children: [
          const Expanded(
            child: Align(alignment: Alignment.centerLeft, child: _AddressPill(compact: true)),
          ),
          const SizedBox(width: 8),
          Material(
            color: scheme.primary,
            borderRadius: AppRadius.button,
            child: IconButton(
              tooltip: 'Buscar',
              onPressed: () => context.goNamed(ExplorePage.name),
              icon: Icon(Icons.search_rounded, color: scheme.onPrimary),
            ),
          ),
          const SizedBox(width: 8),
          const _RoundBell(),
        ],
      ),
    );
  }
}
