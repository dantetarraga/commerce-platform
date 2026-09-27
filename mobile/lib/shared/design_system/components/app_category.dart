import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum AppCategorySize {
  /// Resaltada: la del momento del día (fondo cobalto suave).
  large,
  small,
}

/// Acceso a un tipo de negocio (Comida, Mercado, Botica, Tiendas): mosaico
/// gris con el objeto arriba y el nombre abajo. El resaltado va en cobalto
/// suave, nunca en un color por categoría.
///
/// Cuando existan fotos recortadas de objetos reales (olla, pan, blíster…),
/// se pasan por [image] y reemplazan al ícono sin cambiar la composición.
class AppCategory extends StatelessWidget {
  const AppCategory({
    required this.label,
    required this.icon,
    required this.onTap,
    this.size = AppCategorySize.small,
    this.caption,
    this.image,
    this.tilt = 0,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final AppCategorySize size;

  /// Línea de apoyo, solo en resaltadas ("Menú del día desde S/ 12"). Se
  /// anuncia a lectores de pantalla; visualmente no se muestra en mosaicos chicos.
  final String? caption;
  final ImageProvider? image;

  /// Se conserva por compatibilidad; los mosaicos ya no se inclinan.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlighted = size == AppCategorySize.large;
    final bg = highlighted ? scheme.primary : (theme.brightness == Brightness.dark ? context.chaski.raised : AppColors.terracota50);
    final fg = highlighted ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      onTap: onTap,
      label: caption == null ? label : '$label. $caption',
      excludeSemantics: true,
      child: PressableScale(
        scale: 0.95,
        child: Material(
          color: bg,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxs, AppSpacing.sm, AppSpacing.xxs, AppSpacing.xs + 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 34,
                    child: image != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.all(AppRadius.sm),
                            child: Image(image: image!, fit: BoxFit.cover),
                          )
                        : Transform.rotate(
                            angle: tilt,
                            child: Icon(icon, color: fg, size: highlighted ? 34 : 28),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xxs + 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w800, letterSpacing: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
