import 'package:flutter/material.dart';

/// Los pasos sobre una línea; lo recorrido queda sólido y cada paso alcanzado
/// muestra su hora.
class StepTrail extends StatelessWidget {
  const StepTrail({required this.step, required this.labels, this.times = const [], super.key});

  final int step;
  final List<String> labels;

  /// Hora bajo cada paso ("8:05 pm"); `null` si no se conoce.
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
                final slot = constraints.maxWidth / labels.length;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(left: slot / 2, right: slot / 2, child: _Bar(color: scheme.outlineVariant)),
                    Positioned(left: slot / 2, width: slot * step, child: _Bar(color: scheme.primary)),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
}
