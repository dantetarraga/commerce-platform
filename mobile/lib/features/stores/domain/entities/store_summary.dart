import 'package:chaski/core/domain/money.dart';
import 'package:equatable/equatable.dart';

final class StoreRating extends Equatable {
  const StoreRating({required this.average, required this.count});

  final double average;
  final int count;

  bool get hasReviews => count > 0;

  @override
  List<Object?> get props => [average, count];
}

/// Negocio tal como aparece en listados. Distancia, fee y ETA los calcula el
/// backend para la ubicación del usuario.
final class StoreSummary extends Equatable {
  const StoreSummary({
    required this.id,
    required this.name,
    required this.categoryIds,
    required this.rating,
    required this.distanceKm,
    required this.etaMinutes,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.isOpenNow,
    required this.deliversToYou,
    this.logoUrl,
    this.coverUrl,
    this.tags = const [],
    this.promoLabel,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final List<String> categoryIds;
  final StoreRating rating;
  final double distanceKm;
  final int etaMinutes;
  final Money deliveryFee;
  final Money minOrderAmount;
  final bool isOpenNow;
  final bool deliversToYou;

  /// Momentos del día en los que destaca: `desayuno`, `almuerzo`, `tarde`,
  /// `noche`, `caldos`…
  final List<String> tags;

  /// Oferta vigente del negocio ("−15 % en caldos hoy"), si hay.
  final String? promoLabel;

  /// Se puede pedir ahora mismo.
  bool get canOrder => isOpenNow && deliversToYou;

  @override
  List<Object?> get props => [
    id, name, logoUrl, coverUrl, categoryIds, rating, distanceKm,
    etaMinutes, deliveryFee, minOrderAmount, isOpenNow, deliversToYou, tags, promoLabel,
  ];
}
