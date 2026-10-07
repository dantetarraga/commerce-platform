import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composición de la portada, medida sobre 390 px y anclada al borde derecho.
class HomeCoverArt extends ConsumerWidget {
  const HomeCoverArt({required this.width, super.key});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final x = width - 390;
    final nearest = ref.watch(
      storesProvider(sort: StoreSort.popular).select((s) => s.value?.items.where((s) => s.isOpenNow && s.coverUrl != null).firstOrNull),
    );
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: 300,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: x + 228,
              top: 43,
              width: 210,
              height: 210,
              child: DecoratedBox(decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle)),
            ),
            Positioned(
              left: x + 251,
              top: 66,
              child: const AppNetworkImage(url: 'assets/images/demo/grill.jpg', width: 164, height: 164, borderRadius: BorderRadius.all(Radius.circular(82))),
            ),
            Positioned(
              left: x + 222,
              top: 184,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primaryContainer, width: 3)),
                child: const AppNetworkImage(url: 'assets/images/demo/bread.jpg', width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(21))),
              ),
            ),
            if (nearest != null)
              Positioned(
                right: 8,
                top: 222,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: AppRadius.exit(12),
                      boxShadow: [BoxShadow(color: AppColors.inkOverlay(0.22), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.moped_rounded, size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${nearest.name} · ${nearest.etaMinutes} min',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
