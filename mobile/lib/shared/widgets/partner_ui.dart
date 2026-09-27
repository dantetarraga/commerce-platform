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
