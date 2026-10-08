import 'package:equatable/equatable.dart';


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

  /// Nombre en la API (`?filters=open_now,free_delivery`).
  String get apiName => switch (this) {
    openNow => 'open_now',
    freeDelivery => 'free_delivery',
    topRated => 'top_rated',
    noMinimum => 'no_minimum',
    offers => 'offers',
  };
}

/// Filtros elegidos, comparables por valor: así sirven como parámetro de un
/// provider family aunque la pantalla arme un `Set` nuevo en cada build.
final class StoreFilters extends Equatable {
  const StoreFilters([this.values = const {}]);

  static const none = StoreFilters();

  final Set<StoreFilter> values;

  @override
  List<Object?> get props => [values];
}
