import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Promociones editoriales: tres formatos que se alternan para dar ritmo.
// ---------------------------------------------------------------------------

/// Carril de promociones con formatos distintos: foto, titular grande sobre
/// terracota suave y franja hierba con código.
class EditorialPromos extends StatelessWidget {
  const EditorialPromos({required this.promotions, required this.onTap, this.leading, super.key});

  final List<Promotion> promotions;
  final ValueChanged<Promotion> onTap;

  /// Primera tarjeta del carril (p. ej. un producto que se agrega con "+").
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final height = 268 + (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 30.0) * 7;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: promotions.length + (leading == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (leading != null && i == 0) return leading!;
          final index = leading == null ? i : i - 1;
          final promo = promotions[index];
          final kind = (index + 1) % 3;
          final card = switch (kind) {
            0 => _PhotoPromo(promo: promo),
            1 => _HeadlinePromo(promo: promo),
            _ => _CodePromo(promo: promo),
          };
          return Semantics(
            button: true,
            label: [promo.title, ?promo.subtitle, if (promo.couponCode != null) 'Código ${promo.couponCode}'].join('. '),
            onTap: () => onTap(promo),
            excludeSemantics: true,
            child: PressableScale(
              child: Material(
                color: switch (kind) {
                  0 => Theme.of(context).brightness == Brightness.dark ? context.chaski.raised : AppColors.blanco,
                  1 => AppColors.terracota50,
                  _ => AppColors.hierba,
                },
                borderRadius: AppRadius.card,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onTap(promo),
                  child: SizedBox(width: kind == 1 ? 176 : 216, child: card),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoPromo extends StatelessWidget {
  const _PhotoPromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: AppNetworkImage(
            url: promo.imageUrl,
            width: double.infinity,
            height: 124,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: context.chaski.accent, borderRadius: AppRadius.button),
                  child: Text('Promo', style: theme.textTheme.labelSmall?.copyWith(color: context.chaski.onAccent)),
                ),
                const SizedBox(height: 8),
                Text(promo.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                if (promo.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(promo.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadlinePromo extends StatelessWidget {
  const _HeadlinePromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned(
          right: -22,
          bottom: -22,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.terracota, width: 4),
            ),
            child: AppNetworkImage(url: promo.imageUrl, width: 104, height: 104, borderRadius: const BorderRadius.all(Radius.circular(52))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOY', style: AppTypography.eyebrow(context).copyWith(color: AppColors.terracota700)),
              const SizedBox(height: 8),
              Text(
                promo.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.tinta, height: 1.05),
              ),
              if (promo.subtitle != null) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: 100,
                  child: Text(
                    promo.subtitle!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.piedra),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CodePromo extends StatelessWidget {
  const _CodePromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: AppColors.blanco, size: 18),
              const SizedBox(width: 6),
              Text(promo.couponCode == null ? 'OFERTA' : 'CON CÓDIGO', style: AppTypography.eyebrow(context).copyWith(color: AppColors.blanco)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            promo.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.blanco, height: 1.05),
          ),
          if (promo.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              promo.subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFEFF6EB)),
            ),
          ],
          const Spacer(),
          if (promo.couponCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
              child: Text(promo.couponCode!, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.hierba, letterSpacing: 1)),
            )
          else
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_rounded, color: AppColors.blanco),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Volver a pedir: tarjetas con foto, contexto y acción rápida.
// ---------------------------------------------------------------------------

class RepeatShelf extends StatelessWidget {
  const RepeatShelf({required this.orders, required this.timesByStore, required this.onOpen, required this.onRepeat, super.key});

  final List<Order> orders;

  /// Cuántos pedidos entregados hubo por negocio.
  final Map<String, int> timesByStore;
  final ValueChanged<Order> onOpen;

  /// "Repetir": vuelve a poner el pedido en la bolsa.
  final ValueChanged<Order> onRepeat;

  @override
  Widget build(BuildContext context) {
    final height = 156 + (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 30.0) * 5;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          final times = timesByStore[order.store.id] ?? 1;
          final context0 = times >= 3 ? 'Lo pediste $times veces' : (index == 0 ? 'Tu último pedido' : 'Pediste hace poco');
          return _RepeatCard(
            order: order,
            eyebrow: context0,
            highlight: times >= 3 || index == 0,
            onTap: () => onOpen(order),
            onRepeat: () => onRepeat(order),
          );
        },
      ),
    );
  }
}

class _RepeatCard extends StatelessWidget {
  const _RepeatCard({required this.order, required this.eyebrow, required this.highlight, required this.onTap, required this.onRepeat});

  final Order order;
  final String eyebrow;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = order.lines.map((l) => l.name).join(' + ');
    final total = Formatters.money(order.total);
    return Semantics(
      button: true,
      label: '$eyebrow. ${order.store.name}. $items. $total',
      onTap: onTap,
      explicitChildNodes: true,
      child: PressableScale(
        child: Material(
          color: theme.brightness == Brightness.dark ? context.chaski.raised : AppColors.blanco,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 296,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: order.store.logoUrl,
                      width: 92,
                      height: double.infinity,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(5),
                      ),
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: highlight ? scheme.primary : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(order.store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                          Text(items, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                          const Spacer(),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Text(total, style: AppTypography.price(context, size: 16))),
                              Semantics(
                                button: true,
                                label: 'Repetir pedido de ${order.store.name}',
                                excludeSemantics: true,
                                onTap: onRepeat,
                                child: Material(
                                  color: scheme.primary,
                                  borderRadius: AppRadius.button,
                                  child: InkWell(
                                    borderRadius: AppRadius.button,
                                    onTap: onRepeat,
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.replay_rounded, size: 15, color: scheme.onPrimary),
                                          const SizedBox(width: 4),
                                          Text('Repetir', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

// ---------------------------------------------------------------------------
// Pedido activo: la portada del inicio se convierte en el seguimiento.
// ---------------------------------------------------------------------------

/// Cuatro pasos visibles: Confirmado · Preparando · En camino · Llegando.
int activeOrderStep(Order order, int? minutesLeft) => switch (order.status) {
  OrderStatus.received || OrderStatus.confirmed => 0,
  OrderStatus.preparing || OrderStatus.ready => 1,
  OrderStatus.courierAssigned => 2,
  OrderStatus.onTheWay => minutesLeft != null && minutesLeft <= 3 ? 3 : 2,
  OrderStatus.delivered || OrderStatus.cancelled => 3,
};

/// Seguimiento a todo el ancho bajo la barra compacta: estado, minutos, mapa ilustrado,
/// los cuatro pasos con su hora y quién lo lleva.
class ActiveOrderCover extends StatelessWidget {
  const ActiveOrderCover({required this.order, super.key});

  final Order order;

  static const _steps = ['Confirmado', 'Preparando', 'En camino', 'Llegando'];

  static String _statusLabel(OrderStatus status, int step) => switch (status) {
    OrderStatus.received => 'Recibido',
    OrderStatus.ready => 'Listo para salir',
    OrderStatus.courierAssigned => 'Repartidor asignado',
    _ => _steps[step],
  };

  /// Avance ilustrativo sobre la ruta (no es GPS).
  static double _progress(int step) => switch (step) {
    0 => 0.02,
    1 => 0.12,
    2 => 0.55,
    _ => 0.92,
  };

  void _open(BuildContext context) => context.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id});

  void _help(BuildContext context) => context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': order.id});

  String? _time(OrderStatus status) {
    final at = order.timeOf(status);
    return at == null ? null : Formatters.clock(at);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minutes = order.minutesLeft(DateTime.now());
    final step = activeOrderStep(order, minutes);
    final arrival = order.estimatedArrival;
    final courier = order.courier;
    final riding = courier != null && step >= 2;
    final card = theme.brightness == Brightness.dark ? context.chaski.raised : AppColors.blanco;
    return Semantics(
      container: true,
      label: '${order.store.name}. ${order.headline}${minutes == null ? '' : '. Llega en $minutes minutos'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, AppSpacing.gutter),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.hero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _LiveDot(color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(order.status, step),
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                const Spacer(),
                AppNetworkImage(
                  url: order.store.logoUrl,
                  width: 24,
                  height: 24,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  fallbackIcon: Icons.storefront_rounded,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    order.store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (minutes != null) ...[
                  Text('$minutes', style: AppTypography.price(context, size: 72).copyWith(height: 0.88, color: scheme.onSurface)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('min', style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  const Spacer(),
                ] else
                  Expanded(child: Text(order.headline, style: theme.textTheme.headlineSmall)),
                if (arrival != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Llega', style: theme.textTheme.bodySmall),
                      Text(Formatters.clock(arrival), style: theme.textTheme.titleLarge),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(minutes == null ? order.detail : order.headline, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Ver el recorrido en el mapa',
              onTap: () => _open(context),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _open(context),
                child: ClipRRect(
                  borderRadius: AppRadius.tileExit,
                  child: SizedBox(
                    height: 148,
                    child: CustomPaint(
                      painter: _MiniMapPainter(
                        progress: _progress(step),
                        showRider: riding,
                        base: card,
                        street: scheme.primaryContainer,
                        route: scheme.primary,
                        casing: scheme.outlineVariant,
                      ),
                      child: _MiniMapPins(progress: _progress(step), showRider: riding, logoUrl: order.store.logoUrl),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _StepTrail(
              step: step,
              labels: _steps,
              times: [
                _time(OrderStatus.confirmed) ?? _time(OrderStatus.received),
                _time(OrderStatus.preparing),
                _time(OrderStatus.onTheWay) ?? _time(OrderStatus.courierAssigned),
                _time(OrderStatus.delivered),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: card, borderRadius: AppRadius.tileExit),
              child: Row(
                children: [
                  if (courier != null)
                    AppAvatar(imageUrl: courier.avatarUrl, seed: courier.name, size: 46)
                  else
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                      child: Icon(Icons.moped_rounded, color: scheme.onSurfaceVariant),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courier != null ? '${courier.firstName} te lo lleva' : 'Buscando repartidor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          courier != null ? courier.vehicle : 'Te avisamos al asignarlo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _SquareAction(icon: Icons.chat_bubble_outline_rounded, tooltip: 'Ayuda con tu pedido', filled: false, onTap: () => _help(context)),
                  const SizedBox(width: 8),
                  _SquareAction(icon: Icons.map_outlined, tooltip: 'Ver mapa', filled: true, onTap: () => _open(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.icon, required this.tooltip, required this.filled, required this.onTap});

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : scheme.primaryContainer,
      borderRadius: AppRadius.button,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: filled ? scheme.onPrimary : scheme.primary),
      ),
    );
  }
}

/// La misma doble curva que firma la marca, en miniatura.
Path _miniRoute(Size s) => Path()
  ..moveTo(s.width * 0.12, s.height * 0.76)
  ..lineTo(s.width * 0.42, s.height * 0.76)
  ..cubicTo(s.width * 0.58, s.height * 0.76, s.width * 0.56, s.height * 0.27, s.width * 0.7, s.height * 0.27)
  ..lineTo(s.width * 0.86, s.height * 0.27);

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({
    required this.progress,
    required this.showRider,
    required this.base,
    required this.street,
    required this.route,
    required this.casing,
  });

  final double progress;
  final bool showRider;
  final Color base;
  final Color street;
  final Color route;
  final Color casing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final streets = Paint()
      ..color = street
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    for (final y in [0.27, 0.76]) {
      canvas.drawLine(Offset(-10, size.height * y), Offset(size.width + 10, size.height * y), streets);
    }
    for (final x in [0.2, 0.57, 0.86]) {
      canvas.drawLine(Offset(size.width * x, -10), Offset(size.width * x, size.height + 10), streets);
    }
    canvas.drawLine(Offset(size.width * 0.3, size.height + 10), Offset(size.width * 0.72, -10), streets);
    final path = _miniRoute(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = casing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final metric = path.computeMetrics().first;
    final dots = Paint()..color = route;
    for (var d = 0.0; d < metric.length; d += 9) {
      final p = metric.getTangentForOffset(d)?.position;
      if (p != null) canvas.drawCircle(p, 1.8, dots);
    }
  }

  @override
  bool shouldRepaint(_MiniMapPainter old) => old.progress != progress || old.showRider != showRider || old.base != base || old.route != route;
}

class _MiniMapPins extends StatelessWidget {
  const _MiniMapPins({required this.progress, required this.showRider, required this.logoUrl});

  final double progress;
  final bool showRider;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final metric = _miniRoute(size).computeMetrics().first;
        final rider = metric.getTangentForOffset(metric.length * progress)?.position ?? Offset.zero;
        Widget pin(Offset at, double d, Widget child) => Positioned(left: at.dx - d / 2, top: at.dy - d / 2, width: d, height: d, child: child);
        return Stack(
          children: [
            pin(
              Offset(size.width * 0.12, size.height * 0.76),
              38,
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.chaski.accent, width: 3),
                ),
                child: AppNetworkImage(url: logoUrl, borderRadius: const BorderRadius.all(Radius.circular(19)), fallbackIcon: Icons.storefront_rounded),
              ),
            ),
            pin(
              Offset(size.width * 0.86, size.height * 0.27),
              34,
              Container(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(Icons.home_rounded, size: 16, color: scheme.onPrimary),
              ),
            ),
            if (showRider)
              pin(
                rider,
                36,
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: scheme.surface, width: 3),
                  ),
                  child: Icon(Icons.moped_rounded, size: 18, color: scheme.onPrimary),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 10,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + 1.6 * t,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                ),
                child: const SizedBox.square(dimension: 10),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              child: const SizedBox.square(dimension: 10),
            ),
          ],
        );
      },
    ),
  );
}

/// Los cuatro pasos sobre una línea punteada; lo recorrido queda sólido.
class _StepTrail extends StatelessWidget {
  const _StepTrail({required this.step, required this.labels, this.times = const []});

  final int step;
  final List<String> labels;

  /// Hora bajo cada paso ya alcanzado ("8:05 pm"); vacío si no se conoce.
  final List<String?> times;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final slot = w / labels.length;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: slot / 2,
                      right: slot / 2,
                      child: CustomPaint(size: const Size.fromHeight(2), painter: _DottedLine(scheme.outline)),
                    ),
                    Positioned(
                      left: slot / 2,
                      width: slot * step,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    for (var i = 0; i < labels.length; i++)
                      Positioned(
                        left: slot * i + slot / 2 - 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < step ? scheme.primary : scheme.primaryContainer,
                            border: Border.all(color: i <= step ? scheme.primary : scheme.outline, width: i == step ? 6 : 2),
                          ),
                          child: i < step ? Icon(Icons.check_rounded, size: 14, color: scheme.onPrimary) : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: i <= step ? scheme.onSurface : scheme.onSurfaceVariant,
                          fontWeight: i == step ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (i < times.length && times[i] != null)
                        Text(times[i]!, maxLines: 1, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10.5)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends CustomPainter {
  const _DottedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.color != color;
}
