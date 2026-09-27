import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/components/app_skeleton.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Carrusel paginado: el banner arranca en el margen de la pantalla (alineado
/// con las demás secciones), encaja al soltar y el siguiente asoma a la derecha.
class PromotionsCarousel extends StatefulWidget {
  const PromotionsCarousel({required this.promotions, required this.onTap, super.key});

  static const height = 260.0;
  static double heightOf(BuildContext context) => 88 + MediaQuery.textScalerOf(context).scale(height - 88);
  static const viewportFraction = 0.88;

  /// Espacio entre banners.
  static const double _gap = AppSpacing.xs;

  /// El PageView queda medio hueco por dentro del margen a cada lado: así el
  /// primer banner arranca en el margen y el último termina en el margen.
  static const double _leading = AppSpacing.gutter - _gap / 2;

  final List<Promotion> promotions;
  final ValueChanged<Promotion> onTap;

  @override
  State<PromotionsCarousel> createState() => _PromotionsCarouselState();
}

class _PromotionsCarouselState extends State<PromotionsCarousel> {
  final _controller = PageController(viewportFraction: PromotionsCarousel.viewportFraction);
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotions = widget.promotions;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PromotionsCarousel._leading),
          child: SizedBox(
            height: PromotionsCarousel.heightOf(context),
            child: PageView.builder(
              controller: _controller,
              // Alineado al margen (no centrado); sin recortar para que el
              // siguiente asome más allá del margen.
              padEnds: false,
              clipBehavior: Clip.none,
              itemCount: promotions.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: PromotionsCarousel._gap / 2),
                child: _PromotionBanner(promotion: promotions[index], alternate: index.isOdd, onTap: () => widget.onTap(promotions[index])),
              ),
            ),
          ),
        ),
        if (promotions.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: 'Promoción ${(_page + 1).clamp(1, promotions.length)} de ${promotions.length}',
            child: _Dots(count: promotions.length, current: _page),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
              curve: AppMotion.arrive,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == current ? scheme.primary : scheme.outlineVariant,
                borderRadius: const BorderRadius.all(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({required this.promotion, required this.onTap, required this.alternate});

  final Promotion promotion;
  final VoidCallback onTap;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = alternate ? AppColors.hierba : AppColors.terracota700;
    const foreground = AppColors.blanco;
    return Semantics(
      button: true,
      label: [
        promotion.title,
        if (promotion.subtitle != null) promotion.subtitle!,
        if (promotion.couponCode != null) 'Código ${promotion.couponCode}',
      ].join('. '),
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: background,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(url: promotion.imageUrl),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                          child: Text('BUENA OPORTUNIDAD', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.terracota700, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(color: foreground, height: 1.12),
                        ),
                        if (promotion.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            promotion.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                promotion.couponCode == null ? 'Conocer oferta' : 'Código: ${promotion.couponCode}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: foreground),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Misma geometría que el carrusel: banner en el margen, el siguiente
/// asomando y el hueco de los puntos.
class PromotionsCarouselSkeleton extends StatelessWidget {
  const PromotionsCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final page = (constraints.maxWidth - PromotionsCarousel._leading * 2) * PromotionsCarousel.viewportFraction;
      final banner = page - PromotionsCarousel._gap;
      return SizedBox(
        height: PromotionsCarousel.heightOf(context) + AppSpacing.xs + 6,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: AppSpacing.gutter),
                SkeletonBox(width: banner, height: PromotionsCarousel.heightOf(context), borderRadius: AppRadius.card),
                const SizedBox(width: PromotionsCarousel._gap),
                SkeletonBox(width: banner, height: PromotionsCarousel.heightOf(context), borderRadius: AppRadius.card),
              ],
            ),
          ),
        ),
      );
    },
  );
}
