import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppBadgeStatus { open, closed, fresh }

/// Estado de un negocio o producto. Siempre ícono + texto: nunca solo color.
class AppBadge extends StatelessWidget {
  const AppBadge(this.status, {this.label, super.key});

  final AppBadgeStatus status;

  /// Sobrescribe el texto por defecto ("Abierto", "Cerrado", "Nuevo").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    final (IconData icon, String text, Color color) = switch (status) {
      AppBadgeStatus.open => (Icons.circle, 'Abierto', chaski.success),
      AppBadgeStatus.closed => (Icons.nightlight_round, 'Cerrado', theme.colorScheme.onSurfaceVariant),
      AppBadgeStatus.fresh => (Icons.auto_awesome_rounded, 'Nuevo', theme.colorScheme.primary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: status == AppBadgeStatus.open ? 8 : 13, color: color),
        const SizedBox(width: 5),
        Text(label ?? text, style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}

/// "Cinta" de promoción: relleno lima, texto tinta. Una por negocio o
/// producto, y solo si hay una oferta real.
class AppCinta extends StatelessWidget {
  const AppCinta(this.label, {this.dense = false, super.key});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chaski = context.chaski;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : AppSpacing.xs, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: chaski.accent,
        borderRadius: BorderRadius.all(Radius.circular(dense ? 6 : 8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: chaski.onAccent,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 10 : 11,
        ),
      ),
    );
  }
}
