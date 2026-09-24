import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppAvatarVariant {
  /// Usuario: círculo.
  user,

  /// Repartidor: círculo con un aro cobalto (es "alguien de aquí" en camino).
  courier,

  /// Negocio: logo en mosaico redondeado.
  store,
}

/// Avatar con fallback en cadena:
/// foto real → avatar generado con DiceBear (si hay [seed]) → iniciales → ícono.
///
/// Los negocios no usan DiceBear: sin logo muestran el ícono.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    this.imageUrl,
    this.initials,
    this.seed,
    this.size = 44,
    this.variant = AppAvatarVariant.user,
    this.fallbackIcon = Icons.person_rounded,
    super.key,
  });

  final String? imageUrl;
  final String? initials;

  /// Semilla estable para DiceBear (id del usuario, nombre del repartidor…).
  /// La misma semilla siempre genera el mismo avatar.
  final String? seed;
  final double size;
  final AppAvatarVariant variant;
  final IconData fallbackIcon;

  /// Estilo de DiceBear. Ver https://www.dicebear.com/styles
  static const _diceBearStyle = 'notionists-neutral';

  /// Apágalo en tests: sin red, el avatar cae directo a las iniciales.
  static bool diceBearEnabled = true;

  static Uri diceBearUrl(String seed) => Uri.https('api.dicebear.com', '/9.x/$_diceBearStyle/svg', {
    'seed': seed,
    // Fondos de la paleta: cobalto50 y limaSoft.
    'backgroundColor': 'e6edff,f2fbdb',
  });

  @override
  Widget build(BuildContext context) {
    final radius = variant == AppAvatarVariant.store
        ? AppRadius.tile
        : BorderRadius.all(Radius.circular(size / 2));

    Widget inner;
    if (variant == AppAvatarVariant.store) {
      inner = AppNetworkImage(url: imageUrl, width: size, height: size, borderRadius: radius, fallbackIcon: fallbackIcon);
    } else {
      final generated = _generated(context);
      inner = ClipRRect(
        borderRadius: radius,
        child: SizedBox.square(
          dimension: size,
          child: imageUrl == null
              ? generated
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (_, _) => _initials(context),
                  // Foto rota → mismo camino que "sin foto".
                  errorWidget: (_, _, _) => generated,
                ),
        ),
      );
    }

    if (variant == AppAvatarVariant.courier) {
      final scheme = Theme.of(context).colorScheme;
      inner = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primary, width: 2)),
        child: inner,
      );
    }
    return ExcludeSemantics(child: inner);
  }

  /// DiceBear si hay semilla; mientras carga o si falla, iniciales.
  Widget _generated(BuildContext context) {
    final seed = this.seed;
    if (!diceBearEnabled || seed == null || seed.isEmpty) return _initials(context);
    return SvgPicture.network(
      diceBearUrl(seed).toString(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholderBuilder: _initials,
      errorBuilder: (context, _, _) => _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: initials != null && initials!.isNotEmpty
            ? Text(
                initials!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontSize: size * 0.38,
                ),
              )
            : Icon(fallbackIcon, color: scheme.onPrimaryContainer, size: size * 0.5),
      ),
    );
  }
}
