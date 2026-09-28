import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/app_badge.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/components/app_skeleton.dart';
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

  /// Fotografía amplia y datos fuera de la imagen para listas de descubrimiento.
  editorial,

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
    this.onSchedule,
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

  /// Negocio cerrado (variante editorial): muestra "Programar pedido".
  final VoidCallback? onSchedule;

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
      AppStoreCardVariant.editorial => _Editorial(
        data: data,
        heroTag: heroTag,
        isFavorite: isFavorite ?? false,
        onFavoriteToggle: onFavoriteToggle,
        onSchedule: onSchedule,
      ),
      AppStoreCardVariant.row => ExcludeSemantics(
        child: _Row(data: data, heroTag: heroTag),
      ),
      AppStoreCardVariant.repeat => ExcludeSemantics(
        child: _Repeat(data: data),
      ),
    };
    return Semantics(
      button: true,
      label: _semantics,
      onTap: onTap,
      explicitChildNodes: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: variant == AppStoreCardVariant.row ? null : AppRadius.card,
            child: card,
          ),
        ),
      ),
    );
  }
}

Widget _maybeHero(Object? tag, Widget child) => tag == null ? child : Hero(tag: tag, child: child);

class _Editorial extends StatelessWidget {
  const _Editorial({required this.data, required this.isFavorite, this.heroTag, this.onFavoriteToggle, this.onSchedule});
  final StoreCardData data;
  final bool isFavorite;
  final Object? heroTag;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final fee = data.deliveryFee.isZero ? null : '${Formatters.money(data.deliveryFee)} envío';
    final secondary = [
      if (data.distanceKm != null) Formatters.distance(data.distanceKm!),
      if (data.minOrder != null && !data.minOrder!.isZero) 'mínimo ${Formatters.money(data.minOrder!)}' else 'sin mínimo',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: (constraints.maxWidth * 0.52).clamp(150, 240),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _maybeHero(
                    heroTag,
                    ExcludeSemantics(
                      child: AppNetworkImage(url: data.coverUrl, borderRadius: AppRadius.card),
                    ),
                  ),
                  if (!data.isOpen) const DecoratedBox(decoration: BoxDecoration(color: Color(0x402A1A14), borderRadius: AppRadius.card)),
                  if (data.logoUrl != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: ExcludeSemantics(
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.surface, width: 3)),
                          child: AppNetworkImage(url: data.logoUrl, width: 40, height: 40, borderRadius: const BorderRadius.all(Radius.circular(20))),
                        ),
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavoriteToggle!, onPhoto: true),
                    ),
                  if (data.isOpen && data.promo != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ExcludeSemantics(
                        child: Align(alignment: Alignment.bottomLeft, child: AppCinta(data.promo!)),
                      ),
                    ),
                  if (!data.isOpen)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                            decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.nightlight_round, size: 18, color: AppColors.terracota700),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Cerrado por ahora', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.tinta)),
                                      if (data.closedLabel != null)
                                        Text(
                                          data.closedLabel!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.piedra),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(data.name, style: theme.textTheme.titleLarge)),
                    if (data.rating != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.button),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 15, color: chaski.rating),
                            const SizedBox(width: 3),
                            Text(data.rating!.toStringAsFixed(1), style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (data.subtitle != null) Text(data.subtitle!, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                // Principal: tiempo y envío. Secundario: distancia y mínimo.
                Row(
                  children: [
                    Icon(Icons.moped_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${Formatters.eta(data.etaMinutes)} · '),
                            if (fee != null) TextSpan(text: fee) else TextSpan(text: 'Envío gratis', style: TextStyle(color: chaski.success)),
                          ],
                        ),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 2),
                  child: Text(secondary, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          if (!data.isOpen && onSchedule != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onSchedule,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: const Text('Programar pedido'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.data,
    required this.width,
    required this.isFavorite,
    this.heroTag,
    this.onFavoriteToggle,
  });

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
      child: LayoutBuilder(
        builder: (context, constraints) => ClipRRect(
          borderRadius: AppRadius.card,
          child: SizedBox(
            height: constraints.hasBoundedHeight ? constraints.maxHeight : (width * 0.8).clamp(180.0, 320.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _maybeHero(
                  heroTag,
                  ExcludeSemantics(
                    child: AppNetworkImage(url: data.coverUrl, width: width),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.2, 0.65, 1],
                      colors: [Color(0x002A1A14), Color(0xB02A1A14), Color(0xF02A1A14)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  right: 56,
                  child: ExcludeSemantics(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: data.promo != null
                          ? AppCinta(data.promo!)
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                              child: Text(
                                data.isOpen ? Formatters.eta(data.etaMinutes) : data.closedLabel ?? 'Cerrado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.terracota700),
                              ),
                            ),
                    ),
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavoriteToggle!, onPhoto: true),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.blanco, size: 15),
                              const SizedBox(width: 4),
                              Text(data.rating!.toStringAsFixed(1), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.blanco)),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Text(
                          data.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.blanco, fontSize: width > 300 ? 25 : 20, height: 1.1),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          data.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF1E6DE)),
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
          Flexible(
            child: Text(Formatters.eta(data.etaMinutes), style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
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
  late final _bounce = AnimationController(
    vsync: this,
    duration: AppMotion.story,
  );

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
        final scale = t == 0
            ? 1.0
            : 1 +
                  0.3 *
                      AppMotion.knot.transform(
                        t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6,
                      );
        return Transform.scale(scale: scale, child: child);
      },
      child: Icon(
        widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
        color: color,
      ),
    );
    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: widget.isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          excludeFromSemantics: true,
          child: SizedBox.square(
            dimension: AppSpacing.minTouch,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.onPhoto ? chaski.onPhoto.withValues(alpha: 0.94) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 32,
                  child: Center(child: icon),
                ),
              ),
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
                width: 94,
                height: 104,
                borderRadius: AppRadius.card,
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
                if (data.isOpen) StoreMetaLine(data: data) else AppBadge(AppBadgeStatus.closed, label: data.closedLabel ?? 'Cerrado ahora'),
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

/// Skeleton de cada variante: la misma tarjeta con datos de relleno, así la
/// geometría nunca se desfasa de la real.
class AppStoreCardSkeleton extends StatelessWidget {
  const AppStoreCardSkeleton({this.variant = AppStoreCardVariant.feature, this.width = 248, super.key});

  final AppStoreCardVariant variant;
  final double width;

  static const _placeholder = StoreCardData(
    id: 'skeleton',
    name: 'Picantería Espinar',
    subtitle: 'Caldos · Sopas',
    etaMinutes: 25,
    deliveryFee: Money(300),
    isOpen: true,
    rating: 4.8,
    distanceKm: 1.2,
  );

  static void _noop() {}

  @override
  Widget build(BuildContext context) => AppSkeletonizer(
    child: AppStoreCard(data: _placeholder, onTap: _noop, variant: variant, width: width),
  );
}
