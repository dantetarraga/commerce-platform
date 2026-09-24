import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:equatable/equatable.dart';

enum StoreSort { distance, popular, rating }

/// Criterios para listar negocios. Es inmutable y comparable por valor, así
/// sirve directo como parámetro de un provider family.
final class StoreQuery extends Equatable {
  const StoreQuery({
    required this.location,
    this.sort = StoreSort.distance,
    this.categoryId,
    this.page = 1,
    this.limit = 20,
  });

  final GeoCoordinates location;
  final StoreSort sort;
  final String? categoryId;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [location, sort, categoryId, page, limit];
}
