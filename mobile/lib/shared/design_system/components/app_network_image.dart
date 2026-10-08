import 'package:apamuy/shared/design_system/components/app_skeleton.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart' show Skeletonizer;

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
    // Dentro de un skeleton, la foto es un bloque entero (no su ícono de respaldo).
    if (Skeletonizer.maybeOf(context)?.enabled ?? false) {
      return SizedBox(width: width, height: height, child: SkeletonBox.expand(borderRadius: borderRadius));
    }
    final fallback = _Fallback(icon: fallbackIcon);
    final source = url?.trim();
    final reduced = reduceMotionOf(context);
    final image = source == null || source.isEmpty
        ? fallback
        : source.startsWith('assets/')
        ? Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => fallback,
          )
        : CachedNetworkImage(
            imageUrl: source,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: width != null && width!.isFinite && width! > 0
                ? (width! * MediaQuery.devicePixelRatioOf(context))
                      .ceil()
                      .clamp(1, 1600)
                : null,
            fadeInDuration: reduced ? Duration.zero : AppMotion.base,
            fadeOutDuration: reduced ? Duration.zero : AppMotion.quick,
            placeholder: (_, _) => const Skeleton(child: SkeletonBox.expand()),
            errorWidget: (_, _, _) => fallback,
          );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy =
            constraints.maxWidth >= 120 && constraints.maxHeight >= 88;
        return ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primaryContainer, scheme.surfaceContainer],
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(roomy ? 12 : 6),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: scheme.onPrimaryContainer,
                        size: roomy ? 28 : 20,
                      ),
                    ),
                    if (roomy) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sin foto',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
