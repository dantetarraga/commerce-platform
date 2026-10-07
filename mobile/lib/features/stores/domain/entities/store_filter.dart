import 'package:chaski/features/stores/domain/entities/store_summary.dart';

/// Filtros rápidos de los listados de negocios ("Cerca de ti", categoría).
enum StoreFilter {
  openNow('Abierto ahora'),
  freeDelivery('Envío gratis'),
  topRated('★ 4.5 o más'),
  noMinimum('Sin mínimo'),
  offers('Con ofertas');

  const StoreFilter(this.label);

  final String label;

  /// Los tres que caben en la portada del inicio.
  static const List<StoreFilter> quick = [openNow, freeDelivery, topRated];

  /// Calificación mínima de [topRated].
  static const topRatedMin = 4.5;

  bool accepts(StoreSummary s) => switch (this) {
    openNow => s.isOpenNow,
    freeDelivery => s.deliveryFee.isZero,
    topRated => s.rating.hasReviews && s.rating.average >= topRatedMin,
    noMinimum => s.minOrderAmount.isZero,
    offers => s.promoLabel != null,
  };
}

extension StoreListFilters on Iterable<StoreSummary> {
  /// Los que pasan todos los [filters] (sin filtros, todos).
  List<StoreSummary> matching(Set<StoreFilter> filters) => [
    for (final s in this)
      if (filters.every((f) => f.accepts(s))) s,
  ];

  /// Abiertos primero y cerrados al final, sin perder el orden elegido.
  List<StoreSummary> openFirst() => [...where((s) => s.isOpenNow), ...where((s) => !s.isOpenNow)];
}
