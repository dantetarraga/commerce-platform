import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Al abrir, la pantalla sube como tarjeta con la esquina de salida y la de atrás
/// retrocede. Solo en Android; con "reducir movimiento" el cambio es inmediato.
class RisingCardPageTransitionsBuilder extends PageTransitionsBuilder {
  const RisingCardPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Duration get reverseTransitionDuration => AppMotion.pageReverse;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _RisingCard(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _RisingCard extends StatelessWidget {
  const _RisingCard({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.arrive,
      reverseCurve: Curves.easeInCubic,
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.arrive,
      reverseCurve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([enter, behind]),
      child: child,
      builder: (context, child) {
        final t = enter.value;
        final back = behind.value;
        // Quieta: sin capas extra (ni recorte, ni opacidad, ni sombra).
        if (t >= 1 && back <= 0) return child!;
        final height = MediaQuery.sizeOf(context).height;

        final corners = (1 - t).clamp(0.0, 1.0);
        var page = child!;
        if (corners > 0.001) {
          page = ClipRRect(
            borderRadius: BorderRadius.lerp(
              BorderRadius.zero,
              AppRadius.card * 1.4,
              corners,
            )!,
            child: page,
          );
        }
        if (back > 0.001) {
          page = Stack(
            fit: StackFit.passthrough,
            children: [
              page,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.tinta.withValues(alpha: 0.18 * back),
                  ),
                ),
              ),
            ],
          );
        }
        return Transform.translate(
          offset: Offset(0, height * 0.08 * (1 - t)),
          child: Transform.scale(
            scale: (0.96 + 0.04 * t) * (1 - 0.04 * back),
            // Se vuelve opaca enseguida (el primer 15 % del tiempo): así las dos
            // pantallas no se mezclan.
            child: Opacity(
              opacity: (animation.value / 0.15).clamp(0.0, 1.0),
              child: page,
            ),
          ),
        );
      },
    );
  }
}

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
