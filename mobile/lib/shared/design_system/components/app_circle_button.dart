import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Botón circular con ícono (llamar, mensaje, volver sobre el mapa). El
/// círculo mide [diameter] pero el área táctil siempre es de 48.
///
/// [tooltip] es obligatorio: es lo que dice el lector de pantalla.
class AppCircleButton extends StatelessWidget {
  const AppCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
    this.elevated = false,
    this.diameter = 42,
    this.iconSize = 20,
    super.key,
  }) : assert(diameter <= AppSpacing.minTouch, 'El círculo no puede pasar del área táctil');

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Fondo del círculo; por defecto `surface`.
  final Color? background;

  /// Color del ícono; por defecto `onSurface`.
  final Color? foreground;

  /// Con sombra suave (sobre mapas o fotos).
  final bool elevated;
  final double diameter;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppSpacing.minTouch,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: elevated ? AppShadows.soft(theme.brightness) : null),
              child: Material(
                color: background ?? scheme.surface,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox.square(
                    dimension: diameter,
                    child: Icon(icon, size: iconSize, color: foreground ?? scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
