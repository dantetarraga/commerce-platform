import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Punto "en vivo" con un halo que late (quieto con movimiento reducido).
class LiveDot extends StatefulWidget {
  const LiveDot({required this.color, super.key});

  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: AppMotion.ambient);

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
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.5 * (1 - t))),
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
