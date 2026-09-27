import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Ancho de lectura para las herramientas de trabajo de Chaski Socios.
class PartnerContent extends StatelessWidget {
  const PartnerContent({required this.child, this.maxWidth = 1040, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class PartnerAppTitle extends StatelessWidget {
  const PartnerAppTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHASKI SOCIOS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.4,
          ),
        ),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}

/// Superficie sin sombra: el borde de acento identifica una tarea pendiente.
class PartnerSurface extends StatelessWidget {
  const PartnerSurface({
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final Widget child;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: highlighted ? scheme.primary : scheme.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

class PartnerSectionHeading extends StatelessWidget {
  const PartnerSectionHeading({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    );
  }
}

/// Disponibilidad con texto explícito, además del color y el interruptor.
class PartnerAvailability extends StatelessWidget {
  const PartnerAvailability({
    required this.title,
    required this.message,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.busy = false,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = value ? context.chaski.success : scheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      curve: AppMotion.arrive,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: value ? statusColor.withValues(alpha: 0.35) : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: value ? statusColor.withValues(alpha: 0.1) : context.chaski.raised,
              borderRadius: AppRadius.tile,
            ),
            child: AnimatedSwitcher(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: statusColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (busy)
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Semantics(
              label: title,
              child: Switch(value: value, onChanged: onChanged),
            ),
        ],
      ),
    );
  }
}

class PartnerMetric extends StatelessWidget {
  const PartnerMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: emphasized ? theme.colorScheme.primary : null,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
