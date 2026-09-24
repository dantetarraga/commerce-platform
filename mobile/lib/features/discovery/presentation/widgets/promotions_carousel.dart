import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/components/app_skeleton.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Carrusel paginado: cada banner encaja al soltar y el siguiente asoma.
class PromotionsCarousel extends StatefulWidget {
  const PromotionsCarousel({required this.promotions, required this.onTap, super.key});

  static const height = 150.0;
  static const viewportFraction = 0.86;
  static const double _gap = AppSpacing.xs / 2;

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
        SizedBox(
          height: PromotionsCarousel.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: promotions.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: PromotionsCarousel._gap),
              child: _PromotionBanner(promotion: promotions[index], onTap: () => widget.onTap(promotions[index])),
            ),
          ),
        ),
        if (promotions.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          _Dots(count: promotions.length, current: _page),
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
              curve: AppMotion.postaOut,
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
  const _PromotionBanner({required this.promotion, required this.onTap});

  final Promotion promotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    return PressableScale(
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: promotion.imageUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [chaski.scrim, chaski.scrim.withValues(alpha: 0)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 190,
                        child: Text(
                          promotion.title,
                          style: theme.textTheme.titleLarge?.copyWith(color: chaski.onPhoto),
                        ),
                      ),
                      if (promotion.subtitle != null)
                        SizedBox(
                          width: 190,
                          child: Text(
                            promotion.subtitle!,
                            maxLines: 2,
                            style: theme.textTheme.bodySmall?.copyWith(color: chaski.onPhoto.withValues(alpha: 0.8)),
                          ),
                        ),
                      if (promotion.couponCode != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: chaski.accent,
                            borderRadius: const BorderRadius.all(AppRadius.sm),
                          ),
                          child: Text(
                            promotion.couponCode!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: chaski.onAccent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
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

/// Misma geometría que el carrusel: banner centrado, el siguiente asomando y
/// el hueco de los puntos.
class PromotionsCarouselSkeleton extends StatelessWidget {
  const PromotionsCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final page = constraints.maxWidth * PromotionsCarousel.viewportFraction;
      final inset = (constraints.maxWidth - page) / 2 + PromotionsCarousel._gap;
      final banner = page - PromotionsCarousel._gap * 2;
      return SizedBox(
        height: PromotionsCarousel.height + AppSpacing.xs + 6,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: inset),
                SkeletonBox(width: banner, height: PromotionsCarousel.height, borderRadius: AppRadius.card),
                const SizedBox(width: PromotionsCarousel._gap * 2),
                SkeletonBox(width: banner, height: PromotionsCarousel.height, borderRadius: AppRadius.card),
              ],
            ),
          ),
        ),
      );
    },
  );
}
