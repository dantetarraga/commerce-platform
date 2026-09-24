import 'dart:math' as math;

import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/checkout/presentation/widgets/checkout_format.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Qué hacer tras confirmar.
enum OrderConfirmedAction { track, home }

/// La única celebración grande del flujo: "¡Pedido listo!". Pantalla completa
/// con el check cobalto, un poco de confeti y la mini boleta del pedido.
/// Volver atrás equivale a "Seguir mi pedido".
Future<OrderConfirmedAction> showOrderConfirmed(BuildContext context, {required Order order}) async {
  HapticFeedback.mediumImpact().ignore();
  final result = await Navigator.of(context, rootNavigator: true).push<OrderConfirmedAction>(
    PageRouteBuilder(
      transitionDuration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      pageBuilder: (_, _, _) => _OrderConfirmedPage(order: order),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
  return result ?? OrderConfirmedAction.track;
}

class _OrderConfirmedPage extends StatefulWidget {
  const _OrderConfirmedPage({required this.order});

  final Order order;

  @override
  State<_OrderConfirmedPage> createState() => _OrderConfirmedPageState();
}

class _OrderConfirmedPageState extends State<_OrderConfirmedPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = AppMotion.postaOut]) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final order = widget.order;
    final owner = order.store.ownerName ?? order.store.name;
    final scheduled = order.scheduledFor;
    final message = scheduled == null
        ? '$owner ya lo vio y empieza a prepararlo.'
        : '$owner lo tendrá listo para ${CheckoutFormat.whenPhrase(scheduled, DateTime.now())}.';
    final pop = _interval(0, 0.45, AppMotion.knot);
    final halo = _interval(0.1, 0.7);
    final text = _interval(0.25, 0.7);
    final card = _interval(0.4, 0.85);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(OrderConfirmedAction.track);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _controller,
                        colors: [context.chaski.accent, scheme.primary],
                        still: reduceMotionOf(context),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
                        child: Semantics(
                          liveRegion: true,
                          container: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CheckBadge(pop: pop, halo: halo),
                              const SizedBox(height: AppSpacing.lg),
                              FadeTransition(
                                opacity: text,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(text),
                                  child: Column(
                                    children: [
                                      Text('¡Pedido listo! 🎉', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        message,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FadeTransition(
                                opacity: card,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(card),
                                  child: _OrderMiniCard(order: order),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                    child: Column(
                      children: [
                        AppButton(
                          label: 'Seguir mi pedido',
                          onPressed: () => Navigator.of(context).pop(OrderConfirmedAction.track),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton.secondary(
                          label: 'Volver a Cerca',
                          onPressed: () => Navigator.of(context).pop(OrderConfirmedAction.home),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo cobalto con check y un halo suave que se expande una vez.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.pop, required this.halo});

  final Animation<double> pop;
  final Animation<double> halo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: halo,
            builder: (context, _) => Container(
              width: 112 + 56 * halo.value,
              height: 112 + 56 * halo.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.9 - 0.3 * halo.value),
              ),
            ),
          ),
          ScaleTransition(
            scale: pop,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
              child: Icon(Icons.check_rounded, size: 60, color: scheme.onPrimary, semanticLabel: 'Pedido confirmado'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderMiniCard extends StatelessWidget {
  const _OrderMiniCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = order.itemCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          AppNetworkImage(
            url: order.store.logoUrl,
            width: 48,
            height: 48,
            borderRadius: AppRadius.tile,
            fallbackIcon: Icons.storefront_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido ${order.code}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'producto' : 'productos'} · ${Formatters.money(order.total)} · ${order.payment.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confeti sutil: pocas tiras lima y cobalto que caen un poco y se apagan.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors, required this.still}) : super(repaint: progress);

  final Animation<double> progress;
  final List<Color> colors;
  final bool still;

  static final List<({double x, double y, double drift, double spin, double w, double h})> _pieces = () {
    final r = math.Random(7);
    return [
      for (var i = 0; i < 18; i++)
        (
          x: r.nextDouble(),
          y: 0.04 + r.nextDouble() * 0.3,
          drift: (r.nextDouble() - 0.5) * 0.08,
          spin: (r.nextDouble() - 0.5) * 4,
          w: 6 + r.nextDouble() * 4,
          h: 10 + r.nextDouble() * 6,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 1.0 : Curves.easeOut.transform(progress.value);
    // Aparece rápido, cae un poco y se desvanece hasta quedar tenue.
    final opacity = still ? 0.55 : (t < 0.15 ? t / 0.15 : 1 - 0.45 * ((t - 0.15) / 0.85));
    for (final (i, p) in _pieces.indexed) {
      final dx = (p.x + p.drift * t) * size.width;
      final dy = (p.y + 0.12 * t) * size.height;
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(p.spin * (0.3 + t));
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), const Radius.circular(2));
      canvas
        ..drawRRect(rect, Paint()..color = colors[i % colors.length].withValues(alpha: opacity.clamp(0, 1)))
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.colors != colors || old.still != still;
}
