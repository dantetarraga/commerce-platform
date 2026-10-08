import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/features/stores/domain/entities/store_filter.dart';
import 'package:equatable/equatable.dart';

enum StoreSort { distance, popular, rating }

extension StoreSortLabel on StoreSort {
  /// Opción en la hoja "Ordenar por": "Cercanía", "Más pedidos"…
  String get label => switch (this) {
    StoreSort.distance => 'Cercanía',
    StoreSort.popular => 'Más pedidos',
    StoreSort.rating => 'Mejor calificados',
  };

  /// Dentro de una frase ("Ordenado por cercanía").
  String get inlineLabel => switch (this) {
    StoreSort.distance => 'cercanía',
    StoreSort.popular => 'más pedidos',
    StoreSort.rating => 'calificación',
  };
}

/// Criterios para listar negocios. Es inmutable y comparable por valor, así
/// sirve directo como parámetro de un provider family.
final class StoreQuery extends Equatable {
  const StoreQuery({
    required this.location,
    this.sort = StoreSort.distance,
    this.categoryId,
    this.filters = const {},
    this.openFirst = true,
    this.page = 1,
    this.limit = 20,
  });

  final GeoCoordinates location;
  final StoreSort sort;
  final String? categoryId;

  /// Los aplica el backend (`?filters=`).
  final Set<StoreFilter> filters;

  /// Los abiertos primero (`?openFirst=true`).
  final bool openFirst;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [location, sort, categoryId, filters, openFirst, page, limit];
}
