import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Corazón de favorito: contorno → rebote → relleno.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({required this.isFavorite, required this.onPressed, this.onPhoto = false, super.key});

  final bool isFavorite;
  final VoidCallback onPressed;

  /// Sobre fotografía: círculo blanco detrás.
  final bool onPhoto;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(
    vsync: this,
    duration: AppMotion.story,
  );

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite && !reduceMotionOf(context)) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chaski = context.chaski;
    final color = widget.isFavorite ? chaski.danger : (widget.onPhoto ? AppColors.tinta : scheme.onSurface);
    final icon = AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final t = _bounce.value;
        final scale = t == 0
            ? 1.0
            : 1 +
                  0.3 *
                      AppMotion.knot.transform(
                        t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6,
                      );
        return Transform.scale(scale: scale, child: child);
      },
      child: Icon(
        widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
        color: color,
      ),
    );
    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: widget.isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          excludeFromSemantics: true,
          child: SizedBox.square(
            dimension: AppSpacing.minTouch,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.onPhoto ? chaski.onPhoto.withValues(alpha: 0.94) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 32,
                  child: Center(child: icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
