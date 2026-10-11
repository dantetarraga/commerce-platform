import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Barra de tramos de un pedido en curso: los pasados llenos y el actual que se
/// llena y se vacía a medias, como algo que está pasando. En el último tramo el
/// pedido terminó y queda todo lleno. Con movimiento reducido queda quieto a la mitad.
class AppStageBar extends StatefulWidget {
  const AppStageBar({required this.stages, required this.current, super.key});

  final List<String> stages;
  final int current;

  @override
  State<AppStageBar> createState() => _AppStageBarState();
}

class _AppStageBarState extends State<AppStageBar> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final Animation<double> _fill = Tween<double>(begin: 0.2, end: 0.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true).ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final track = scheme.onSurface.withValues(alpha: 0.12);
    final stages = widget.stages;
    final current = widget.current;
    final finished = current == stages.length - 1;

    Widget segment(double value) => ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(value: value, minHeight: 6, color: scheme.primary, backgroundColor: track),
    );

    return Semantics(
      label: 'Paso ${current + 1} de ${stages.length}: ${stages[current]}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: i == current && !finished
                      ? AnimatedBuilder(animation: _fill, builder: (context, _) => segment(_fill.value))
                      : segment(i < current || finished ? 1 : 0),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              for (var i = 0; i < stages.length; i++)
                Expanded(
                  child: Text(
                    stages[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == current ? scheme.primary : (i < current ? scheme.onSurface : scheme.onSurfaceVariant),
                      fontWeight: i == current ? FontWeight.w700 : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
