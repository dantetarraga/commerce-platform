import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Etiqueta viva: punto con halo que late y texto en mayúsculas ("EN CAMINO").
/// Con [live] en `false` (entregado, cancelado) el punto queda quieto; con
/// movimiento reducido, también.
class AppLiveTag extends StatefulWidget {
  const AppLiveTag({required this.label, this.live = true, this.color, super.key});

  /// Texto en mayúsculas; el lector de pantalla lo lee en minúsculas.
  final String label;

  /// Late mientras el pedido está en curso.
  final bool live;

  /// Color del punto y del texto; por defecto el primario.
  final Color? color;

  @override
  State<AppLiveTag> createState() => _AppLiveTagState();
}

class _AppLiveTagState extends State<AppLiveTag> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: AppMotion.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppLiveTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.live && !reduceMotionOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true).ignore();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: widget.label.toLowerCase(),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.live)
                    Container(
                      width: 9 + 7 * _pulse.value,
                      height: 9 + 7 * _pulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.28 * (1 - _pulse.value * 0.6)),
                      ),
                    ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}
