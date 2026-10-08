import 'package:apamuy/core/utils/text_scale.dart';
import 'package:apamuy/features/discovery/discovery.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Carril de promociones con tres formatos que se alternan: foto, titular
/// sobre terracota suave y franja hierba con código.
class EditorialPromos extends StatelessWidget {
  const EditorialPromos({required this.promotions, required this.onTap, this.leading, super.key});

  final List<Promotion> promotions;
  final ValueChanged<Promotion> onTap;

  /// Primera tarjeta del carril (p. ej. un producto que se agrega con "+").
  final Widget? leading;

  static double heightOf(BuildContext context) => 268 + textScaleExtra(context, max: 30) * 7;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightOf(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: promotions.length + (leading == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (leading != null && i == 0) return leading!;
          final index = leading == null ? i : i - 1;
          final promo = promotions[index];
          final kind = (index + 1) % 3;
          return AppTapSurface(
            semanticLabel: [promo.title, ?promo.subtitle, if (promo.couponCode != null) 'Código ${promo.couponCode}'].join('. '),
            color: switch (kind) {
              0 => context.apamuy.card,
              1 => AppColors.terracota50,
              _ => AppColors.hierba,
            },
            onTap: () => onTap(promo),
            child: SizedBox(
              width: kind == 1 ? 176 : 216,
              child: switch (kind) {
                0 => _PhotoPromo(promo: promo),
                1 => _HeadlinePromo(promo: promo),
                _ => _CodePromo(promo: promo),
              },
            ),
          );
        },
      ),
    );
  }
}

/// La tarjeta de producto y las promos con sus anchos, mientras carga.
class EditorialPromosSkeleton extends StatelessWidget {
  const EditorialPromosSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final height = EditorialPromos.heightOf(context);
    return Skeleton(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SkeletonBox(width: const [212.0, 176.0, 216.0][i], height: height, borderRadius: AppRadius.card),
        ),
      ),
    );
  }
}

class _PhotoPromo extends StatelessWidget {
  const _PhotoPromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apamuy = context.apamuy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          // Ancho real para que la foto se decodifique a su tamaño en pantalla.
          child: LayoutBuilder(
            builder: (context, box) =>
                AppNetworkImage(url: promo.imageUrl, width: box.maxWidth, height: 124, borderRadius: AppRadius.exit(18)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: apamuy.accent, borderRadius: AppRadius.button),
                  child: Text('Promo', style: theme.textTheme.labelSmall?.copyWith(color: apamuy.onAccent)),
                ),
                const SizedBox(height: 8),
                Text(promo.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                if (promo.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(promo.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadlinePromo extends StatelessWidget {
  const _HeadlinePromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned(
          right: -22,
          bottom: -22,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.terracota, width: 4),
            ),
            child: AppNetworkImage(url: promo.imageUrl, width: 104, height: 104, borderRadius: const BorderRadius.all(Radius.circular(52))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOY', style: AppTypography.eyebrow(context).copyWith(color: AppColors.terracota700)),
              const SizedBox(height: 8),
              Text(
                promo.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.tinta, height: 1.05),
              ),
              if (promo.subtitle != null) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: 100,
                  child: Text(
                    promo.subtitle!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.piedra),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CodePromo extends StatelessWidget {
  const _CodePromo({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: AppColors.blanco, size: 18),
              const SizedBox(width: 6),
              Text(
                promo.couponCode == null ? 'OFERTA' : 'CON CÓDIGO',
                style: AppTypography.eyebrow(context).copyWith(color: AppColors.blanco),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            promo.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.blanco, height: 1.05),
          ),
          if (promo.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              promo.subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: context.apamuy.onPhotoMuted),
            ),
          ],
          const Spacer(),
          if (promo.couponCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
              child: Text(promo.couponCode!, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.hierba, letterSpacing: 1)),
            )
          else
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_rounded, color: AppColors.blanco),
            ),
        ],
      ),
    );
  }
}
