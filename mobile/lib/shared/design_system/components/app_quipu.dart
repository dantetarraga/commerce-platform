import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum QuipuKnot {
  /// Cumplido: punto cobalto.
  done,

  /// En curso: el punto late con un halo.
  current,

  /// Pendiente: punto gris.
  todo,
}

@immutable
class QuipuStep {
  const QuipuStep({
    required this.title,
    required this.knot,
    this.subtitle,
    this.trailing,
    this.child,
    this.onTap,
    this.semanticsHint,
  });

  final String title;
  final String? subtitle;

  /// Hora o dato corto a la derecha ("7:03").
  final String? trailing;

  /// Contenido expandido bajo el título (p. ej. métodos de pago en checkout).
  final Widget? child;
  final QuipuKnot knot;
  final VoidCallback? onTap;
  final String? semanticsHint;
}

/// Cuerda vertical con nudos: cada paso cumplido queda anudado. Se usa en el
/// checkout (bloques ya resueltos) y en el seguimiento del pedido.
class AppQuipu extends StatelessWidget {
  const AppQuipu({required this.steps, this.dense = false, super.key});

  final List<QuipuStep> steps;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          _QuipuRow(step: steps[i], isLast: i == steps.length - 1, next: i + 1 < steps.length ? steps[i + 1] : null, dense: dense),
      ],
    );
  }
}

class _QuipuRow extends StatelessWidget {
  const _QuipuRow({required this.step, required this.isLast, required this.next, required this.dense});

  final QuipuStep step;
  final QuipuStep? next;
  final bool isLast;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    // El tramo hacia el siguiente paso va en cobalto si este ya se cumplió.
    final lineColor = step.knot == QuipuKnot.done ? chaski.thread : scheme.outlineVariant;
    final todo = step.knot == QuipuKnot.todo;

    final state = switch (step.knot) {
      QuipuKnot.done => 'completado',
      QuipuKnot.current => 'en curso',
      QuipuKnot.todo => 'pendiente',
    };

    final content = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (dense ? AppSpacing.sm : AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: (dense ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                        color: todo ? scheme.onSurfaceVariant : scheme.onSurface,
                      ),
                    ),
                    if (step.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(step.subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (step.trailing != null)
                Text(
                  step.trailing!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              if (step.onTap != null) Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
          if (step.child != null) ...[const SizedBox(height: AppSpacing.sm), step.child!],
        ],
      ),
    );

    return Semantics(
      label: '${step.title}, $state',
      hint: step.semanticsHint,
      button: step.onTap != null,
      child: InkWell(
        onTap: step.onTap,
        borderRadius: const BorderRadius.all(AppRadius.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    _KnotDot(knot: step.knot),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: AnimatedContainer(
                            duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
                            width: 2,
                            color: lineColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnotDot extends StatefulWidget {
  const _KnotDot({required this.knot});

  final QuipuKnot knot;

  @override
  State<_KnotDot> createState() => _KnotDotState();
}

class _KnotDotState extends State<_KnotDot> with TickerProviderStateMixin {
  late final _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final _tie = AnimationController(vsync: this, duration: AppMotion.story, value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(_KnotDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al pasar a cumplido, el nudo "se ata" con un salto.
    if (oldWidget.knot != QuipuKnot.done && widget.knot == QuipuKnot.done && !reduceMotionOf(context)) {
      _tie.forward(from: 0);
    }
    _syncBreath();
  }

  void _syncBreath() {
    if (widget.knot == QuipuKnot.current && !reduceMotionOf(context)) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _tie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chaski = context.chaski;
    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _tie]),
      builder: (context, _) {
        final tie = AppMotion.knot.transform(_tie.value);
        // Cumplido: punto cobalto. En curso: punto cobalto con halo. Pendiente: gris.
        final (Color fill, double size) = switch (widget.knot) {
          QuipuKnot.done => (chaski.thread, 12.0 * tie.clamp(0.0, 1.3)),
          QuipuKnot.current => (chaski.thread, 12.0),
          QuipuKnot.todo => (scheme.surfaceContainerHigh, 10.0),
        };
        return SizedBox.square(
          dimension: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.knot == QuipuKnot.current)
                Container(
                  width: 14 + 10 * _breath.value,
                  height: 14 + 10 * _breath.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chaski.thread.withValues(alpha: 0.25 * (1 - _breath.value * 0.5)),
                  ),
                ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}
