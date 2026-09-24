import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Imagen remota con caché, placeholder y fallback consistentes.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIcon = Icons.restaurant_rounded,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(icon: fallbackIcon);
    final image = url == null
        ? fallback
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 150),
            // Mientras descarga: shimmer, igual que los skeletons.
            placeholder: (_, _) => const _Loading(),
            errorWidget: (_, _, _) => fallback,
          );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainer,
      highlightColor: scheme.surfaceContainerLowest,
      child: ColoredBox(color: scheme.surfaceContainer, child: const SizedBox.expand()),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(child: Icon(icon, color: scheme.onSurfaceVariant.withValues(alpha: 0.5))),
    );
  }
}
