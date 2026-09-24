import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/app_badge.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Datos que una card de negocio necesita. El design system no conoce las
/// entidades de los features: cada feature arma este objeto.
@immutable
class StoreCardData {
  const StoreCardData({
    required this.id,
    required this.name,
    required this.etaMinutes,
    required this.deliveryFee,
    required this.isOpen,
    this.coverUrl,
    this.logoUrl,
    this.distanceKm,
    this.rating,
    this.promo,
    this.closedLabel,
    this.subtitle,
    this.minOrder,
  });

  final String id;
  final String name;
  final String? coverUrl;
  final String? logoUrl;
  final int etaMinutes;
  final Money deliveryFee;
  final bool isOpen;
  final double? distanceKm;
  final double? rating;

  /// Texto de la cinta de oferta ("−15 % en caldos hoy").
  final String? promo;

  /// Cuando está cerrado: "Abre mañana 7:00".
  final String? closedLabel;

  /// Una línea de contexto opcional ("Caldos · Sopas").
  final String? subtitle;

  /// Pedido mínimo del negocio (null o cero = sin mínimo).
  final Money? minOrder;

  String get minOrderLabel => minOrder == null || minOrder!.isZero ? 'Sin mínimo' : 'Pedido mín. ${Formatters.money(minOrder!)}';

  /// "20–30 min · Envío S/ 3.00" — lo único necesario para decidir.
  String get meta {
    final fee = deliveryFee.isZero ? 'Envío gratis' : 'Envío ${Formatters.money(deliveryFee)}';
    return '${Formatters.eta(etaMinutes)} · $fee';
  }
}

enum AppStoreCardVariant {
  /// Foto grande 16:9 con logo, oferta y favorito encima (colecciones).
  feature,

  /// Fila compacta con logo ("De tu barrio").
  row,

  /// Solo logo y nombre ("Volver a pedir").
  repeat,
}

class AppStoreCard extends StatelessWidget {
  const AppStoreCard({
    required this.data,
    required this.onTap,
    this.variant = AppStoreCardVariant.feature,
    this.width,
    this.heroTag,
    this.isFavorite,
    this.onFavoriteToggle,
    super.key,
  });

  final StoreCardData data;
  final VoidCallback onTap;
  final AppStoreCardVariant variant;
  final double? width;

  /// Si se indica, la foto vuela a la portada del detalle (elemento compartido).
  final Object? heroTag;

  /// Con [onFavoriteToggle] aparece el corazón sobre la foto (variante feature).
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;

  String get _semantics {
    final parts = [
      data.name,
      if (!data.isOpen) data.closedLabel ?? 'Cerrado',
      if (data.rating != null) 'Calificación ${data.rating!.toStringAsFixed(1)}',
      data.meta.replaceAll('·', ','),
      if (data.minOrder != null) data.minOrderLabel,
      if (data.promo != null) 'Oferta: ${data.promo}',
    ];
    return parts.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final card = switch (variant) {
      AppStoreCardVariant.feature => _Feature(
        data: data,
        width: width ?? 248,
        heroTag: heroTag,
        isFavorite: isFavorite ?? false,
        onFavoriteToggle: onFavoriteToggle,
      ),
      AppStoreCardVariant.row => _Row(data: data, heroTag: heroTag),
      AppStoreCardVariant.repeat => _Repeat(data: data),
    };
    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: variant == AppStoreCardVariant.row ? null : AppRadius.card,
            child: card,
          ),
        ),
      ),
    );
  }
}

Widget _maybeHero(Object? tag, Widget child) => tag == null ? child : Hero(tag: tag, child: child);

class _Feature extends StatelessWidget {
  const _Feature({required this.data, required this.width, required this.isFavorite, this.heroTag, this.onFavoriteToggle});

  final StoreCardData data;
  final double width;
  final Object? heroTag;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _maybeHero(
                heroTag,
                Opacity(
                  opacity: data.isOpen ? 1 : 0.55,
                  child: AppNetworkImage(url: data.coverUrl, width: width, height: width * 0.56, borderRadius: AppRadius.card),
                ),
              ),
              if (data.promo != null) Positioned(left: AppSpacing.xs, top: AppSpacing.xs, child: AppCinta(data.promo!)),
              if (onFavoriteToggle != null)
                Positioned(
                  right: AppSpacing.xxs,
                  top: AppSpacing.xxs,
                  child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavoriteToggle!, onPhoto: true),
                ),
              if (data.logoUrl != null && data.isOpen)
                Positioned(left: AppSpacing.xs, bottom: AppSpacing.xs, child: _LogoChip(url: data.logoUrl!)),
              if (!data.isOpen)
                Positioned(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: _ClosedPill(label: data.closedLabel ?? 'Cerrado ahora'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(data.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          StoreMetaLine(data: data),
        ],
      ),
    );
  }
}

/// Logo del negocio sobre la foto: mosaico blanco pequeño.
class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.chaski.onPhoto,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        boxShadow: AppShadows.soft(Brightness.light),
      ),
      child: AppNetworkImage(url: url, width: 30, height: 30, borderRadius: const BorderRadius.all(Radius.circular(9))),
    );
  }
}

/// "★ 4.8 · 20–30 min · Envío gratis": una sola línea, el envío gratis en verde.
class StoreMetaLine extends StatelessWidget {
  const StoreMetaLine({required this.data, super.key});

  final StoreCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    final muted = theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600);
    final free = data.deliveryFee.isZero;
    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), shape: BoxShape.circle),
      ),
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          if (data.rating != null) ...[
            Icon(Icons.star_rounded, size: 15, color: chaski.rating),
            const SizedBox(width: 2),
            Text(data.rating!.toStringAsFixed(1), style: muted.copyWith(color: theme.colorScheme.onSurface)),
            dot(),
          ],
          Flexible(child: Text(Formatters.eta(data.etaMinutes), style: muted, maxLines: 1, overflow: TextOverflow.ellipsis)),
          dot(),
          Flexible(
            child: Text(
              free ? 'Envío gratis' : 'Envío ${Formatters.money(data.deliveryFee)}',
              style: free ? muted.copyWith(color: chaski.success) : muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

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
  late final _bounce = AnimationController(vsync: this, duration: AppMotion.story);

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
        final scale = t == 0 ? 1.0 : 1 + 0.3 * AppMotion.knot.transform(t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6);
        return Transform.scale(scale: scale, child: child);
      },
      child: Icon(widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: color),
    );
    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: widget.isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSpacing.minTouch,
        child: Center(
          child: Material(
            color: widget.onPhoto ? chaski.onPhoto.withValues(alpha: 0.94) : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: SizedBox.square(dimension: 32, child: Center(child: icon)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.data, this.heroTag});

  final StoreCardData data;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _maybeHero(
            heroTag,
            Opacity(
              opacity: data.isOpen ? 1 : 0.55,
              child: AppNetworkImage(
                url: data.coverUrl ?? data.logoUrl,
                width: 68,
                height: 68,
                borderRadius: const BorderRadius.all(AppRadius.lg),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                if (data.isOpen)
                  StoreMetaLine(data: data)
                else
                  AppBadge(AppBadgeStatus.closed, label: data.closedLabel ?? 'Cerrado ahora'),
                if (data.minOrder != null || data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle ?? data.minOrderLabel,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (data.promo != null) ...[const SizedBox(height: AppSpacing.xxs), AppCinta(data.promo!, dense: true)],
              ],
            ),
          ),
          if (data.distanceKm != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              Formatters.distance(data.distanceKm!),
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _Repeat extends StatelessWidget {
  const _Repeat({required this.data});

  final StoreCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppNetworkImage(url: data.logoUrl, width: 64, height: 64, borderRadius: AppRadius.tile),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(Icons.replay_rounded, size: 13, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ClosedPill extends StatelessWidget {
  const _ClosedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: const BorderRadius.all(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nightlight_round, size: 12, color: scheme.onInverseSurface),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onInverseSurface)),
        ],
      ),
    );
  }
}

/// Skeletons con la misma geometría que cada variante.
class AppStoreCardSkeleton extends StatelessWidget {
  const AppStoreCardSkeleton({this.variant = AppStoreCardVariant.feature, this.width = 248, super.key});

  final AppStoreCardVariant variant;
  final double width;

  @override
  Widget build(BuildContext context) {
    final base = context.chaski.shimmerBase;
    Widget box(double w, double h, [BorderRadius r = const BorderRadius.all(AppRadius.sm)]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: base, borderRadius: r));
    return switch (variant) {
      AppStoreCardVariant.feature => SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(width, width * 0.56, AppRadius.card),
            const SizedBox(height: AppSpacing.xs),
            box(width * 0.6, 16),
            const SizedBox(height: 6),
            box(width * 0.75, 12),
          ],
        ),
      ),
      AppStoreCardVariant.row => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
        child: Row(
          children: [
            box(68, 68, const BorderRadius.all(AppRadius.lg)),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [box(150, 15), const SizedBox(height: 8), box(190, 12)],
            ),
          ],
        ),
      ),
      AppStoreCardVariant.repeat => Column(
        children: [box(64, 64, AppRadius.tile), const SizedBox(height: 6), box(56, 10)],
      ),
    };
  }
}
