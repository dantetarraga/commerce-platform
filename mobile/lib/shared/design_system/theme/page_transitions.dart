import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Contenedor de las pestañas: la nueva entra con fundido y subida leve; las demás
/// quedan montadas (conservan estado y scroll) pero ocultas y sin animaciones.
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.base,
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.arrive,
  );

  @override
  void didUpdateWidget(AnimatedBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      if (reduceMotionOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0).ignore();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (final (i, branch) in widget.children.indexed)
        if (i == widget.currentIndex)
          FadeTransition(
            opacity: _curve,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(_curve),
              child: branch,
            ),
          )
        else
          Offstage(child: TickerMode(enabled: false, child: branch)),
    ],
  );
}
