import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
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

/// Avatar con fallback: foto → ilustración DiceBear local (si hay [seed]) →
/// iniciales → ícono. Los negocios no usan DiceBear.
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

  /// Selecciona una ilustración empaquetada de forma estable, sin enviar
  /// identificadores ni nombres a un servicio externo.
  final String? seed;
  final double size;
  final AppAvatarVariant variant;
  final IconData fallbackIcon;

  static String illustrationAsset(String seed) {
    // Hash acotado: el resultado coincide en Dart VM y web.
    final hash = seed.runes.fold(
      0,
      (value, rune) => (value * 31 + rune) % 65521,
    );
    return 'assets/avatars/notionist_${hash % 12}.svg';
  }

  @override
  Widget build(BuildContext context) {
    final radius = variant == AppAvatarVariant.store ? AppRadius.tile : BorderRadius.all(Radius.circular(size / 2));

    Widget inner;
    if (variant == AppAvatarVariant.store) {
      inner = AppNetworkImage(
        url: imageUrl,
        width: size,
        height: size,
        borderRadius: radius,
        fallbackIcon: fallbackIcon,
      );
    } else {
      final generated = _generated(context);
      final photo = imageUrl?.trim();
      inner = ClipRRect(
        borderRadius: radius,
        child: SizedBox.square(
          dimension: size,
          child: photo == null || photo.isEmpty
              ? generated
              : CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
                  fadeInDuration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => generated,
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: inner,
      );
    }
    return ExcludeSemantics(child: inner);
  }

  /// Ilustración disponible también sin conexión y en las pruebas.
  Widget _generated(BuildContext context) {
    final seed = this.seed;
    if (seed == null || seed.trim().isEmpty) return _initials(context);
    return SvgPicture.asset(
      illustrationAsset(seed),
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
            : Icon(
                fallbackIcon,
                color: scheme.onPrimaryContainer,
                size: size * 0.5,
              ),
      ),
    );
  }
}
