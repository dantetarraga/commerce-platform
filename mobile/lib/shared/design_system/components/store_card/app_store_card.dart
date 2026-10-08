import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/shared/design_system/components/app_skeleton.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_data.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_editorial.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_feature.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_repeat.dart';
import 'package:apamuy/shared/design_system/components/store_card/store_card_row.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

export 'favorite_button.dart';
export 'store_card_data.dart';
export 'store_card_parts.dart';

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

/// Card de negocio; cada variante vive en `store_card/`. Esta clase pone la
/// semántica (un solo botón con todo el resumen), la escala y la onda.
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
      AppStoreCardVariant.feature => StoreCardFeature(
        data: data,
        width: width ?? 248,
        heroTag: heroTag,
        isFavorite: isFavorite ?? false,
        onFavoriteToggle: onFavoriteToggle,
      ),
      AppStoreCardVariant.editorial => StoreCardEditorial(
        data: data,
        heroTag: heroTag,
        isFavorite: isFavorite ?? false,
        onFavoriteToggle: onFavoriteToggle,
        onSchedule: onSchedule,
      ),
      AppStoreCardVariant.row => ExcludeSemantics(
        child: StoreCardRow(data: data, heroTag: heroTag),
      ),
      AppStoreCardVariant.repeat => ExcludeSemantics(
        child: StoreCardRepeat(data: data),
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
