import 'package:chaski/shared/design_system/components/app_loader.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Acción principal de la pantalla (una sola).
  primary,

  /// Acción de apoyo, con peso visual.
  secondary,

  /// Acción terciaria o de navegación.
  ghost,

  /// Eliminar, cancelar un pedido.
  danger,

  /// Acción firme en tinta (en oscuro, texto claro invertido): avanzar una
  /// comanda o una entrega en Apamuy Socios sin competir con el terracota.
  ink,
}

enum AppButtonSize { lg, md, sm }

/// Botón de Apamuy con esquina de salida ([AppRadius.button]), no píldora. Con
/// [loading] el contenido cruza a un indicador sin cambiar el tamaño del botón.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
    super.key,
  });

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.lg,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.lg,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
    super.key,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ink({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.lg,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
    super.key,
  }) : variant = AppButtonVariant.ink;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Widget? trailing;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  double get _height => switch (size) {
    AppButtonSize.lg => 52,
    AppButtonSize.md => 48,
    AppButtonSize.sm => 48,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chaski = context.chaski;
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      AppButtonVariant.primary => (scheme.primary, scheme.onPrimary, BorderSide.none),
      AppButtonVariant.secondary => (chaski.raised, scheme.onSurface, BorderSide.none),
      AppButtonVariant.ghost => (Colors.transparent, scheme.primary, BorderSide.none),
      AppButtonVariant.danger => (Colors.transparent, chaski.danger, BorderSide(color: chaski.danger, width: 1.5)),
      AppButtonVariant.ink => Theme.of(context).brightness == Brightness.dark
          ? (scheme.onSurface, scheme.surface, BorderSide.none)
          : (AppColors.tinta, AppColors.blanco, BorderSide.none),
    };
    final disabledBg = variant == AppButtonVariant.primary || variant == AppButtonVariant.secondary || variant == AppButtonVariant.ink
        ? scheme.onSurface.withValues(alpha: 0.08)
        : Colors.transparent;
    final disabledFg = scheme.onSurface.withValues(alpha: 0.38);

    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.button,
      side: enabled || loading ? side : side.copyWith(color: disabledFg),
    );
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: size == AppButtonSize.sm ? 14 : 16,
      fontWeight: FontWeight.w800,
      color: enabled || loading ? fg : disabledFg,
    );

    final content = AnimatedSwitcher(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1).animate(animation), child: child),
      ),
      child: loading
          ? AppLoader(key: const ValueKey('loading'), size: 22, color: fg, semanticsLabel: null)
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: trailing == null ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.xs)],
                      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
              ],
            ),
    );

    final button = Material(
      color: enabled || loading ? bg : disabledBg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _height, minWidth: AppSpacing.minTouch),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size == AppButtonSize.sm ? AppSpacing.sm : AppSpacing.lg),
            child: IconTheme.merge(
              data: IconThemeData(color: enabled || loading ? fg : disabledFg),
              child: DefaultTextStyle.merge(
                style: textStyle,
                child: Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: enabled ? PressableScale(child: button) : button,
      ),
    );
  }
}
