import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Un tramo del riel: su nombre y su ícono.
typedef OrderStage = ({String label, IconData icon});

/// Riel del seguimiento: cuatro baldosas unidas por una línea. Cada tramo
/// cumplido se rellena en terracota, el actual se resalta y salta, y los que
/// faltan van en gris. Con [travel] (en camino) la línea hacia el último tramo
/// se llena según el trayecto del repartidor.
class OrderStageTrack extends StatefulWidget {
  const OrderStageTrack({required this.stages, required this.current, this.travel, super.key});

  final List<OrderStage> stages;
  final int current;

  /// Avance (0 a 1) del tramo actual hacia el siguiente.
  final double? travel;

  @override
  State<OrderStageTrack> createState() => _OrderStageTrackState();
}

class _OrderStageTrackState extends State<OrderStageTrack> with SingleTickerProviderStateMixin {
  static const _tile = 36.0;
  static const _rail = 4.0;
  static const double _height = _tile + 8;

  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _bob = Tween<double>(begin: 0, end: -3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _finished => widget.current == widget.stages.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(OrderStageTrack old) {
    super.didUpdateWidget(old);
    _syncMotion();
  }

  void _syncMotion() {
    if (reduceMotionOf(context) || _finished) {
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true).ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _tileOf(ColorScheme scheme, IconData icon, {required bool done, required bool now}) {
    final (Color bg, Color fg) = done
        ? (scheme.primary, scheme.onPrimary)
        : now
        ? (scheme.primaryContainer, scheme.primary)
        : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    return Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.exit(12, cut: 4),
        border: now ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Icon(icon, size: 19, color: fg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stages = widget.stages;
    final current = widget.current;
    final n = stages.length;
    final travel = _finished ? 0.0 : (widget.travel ?? 0);
    final trip = widget.travel == null || _finished ? '' : ', ${(travel * 100).round()} % del trayecto';

    return Semantics(
      label: 'Paso ${current + 1} de $n: ${stages[current].label}$trip',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: _height,
            child: LayoutBuilder(
              builder: (context, box) {
                // La línea va del centro de la primera baldosa al de la última.
                final inset = box.maxWidth / n / 2;
                final span = box.maxWidth - inset * 2;
                const top = (_height - _rail) / 2;
                return Stack(
                  children: [
                    Positioned(left: inset, width: span, top: top, height: _rail, child: _railBar(scheme.outlineVariant)),
                    Positioned(
                      left: inset,
                      top: top,
                      height: _rail,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: (current + travel) / (n - 1)),
                        duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
                        builder: (context, reached, _) => SizedBox(width: span * reached, child: _railBar(scheme.primary)),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: Center(
                                child: i == current && !_finished
                                    ? AnimatedBuilder(
                                        animation: _bob,
                                        builder: (context, child) => Transform.translate(offset: Offset(0, _bob.value), child: child),
                                        child: _tileOf(scheme, stages[i].icon, done: false, now: true),
                                      )
                                    : _tileOf(scheme, stages[i].icon, done: i < current || _finished, now: false),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Text(
                    stages[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == current && !_finished ? scheme.primary : (i <= current ? scheme.onSurface : scheme.onSurfaceVariant),
                      fontWeight: i == current && !_finished ? FontWeight.w700 : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _railBar(Color color) => DecoratedBox(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(_rail / 2)),
  );
}
