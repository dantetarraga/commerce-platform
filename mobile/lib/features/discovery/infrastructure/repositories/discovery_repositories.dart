import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/infrastructure/datasources/local_products_remote_data_source.dart';
import 'package:chaski/features/discovery/infrastructure/datasources/promotions_remote_data_source.dart';
import 'package:chaski/features/discovery/infrastructure/datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<Result<SearchResults>> search(String query, GeoCoordinates location, {bool openOnly = false}) =>
      guard(() async => (await _remote.search(query, location, openOnly: openOnly)).toDomain());
}

class PromotionsRepositoryImpl implements PromotionsRepository {
  const PromotionsRepositoryImpl(this._remote);

  final PromotionsRemoteDataSource _remote;

  @override
  Future<Result<List<Promotion>>> getActivePromotions() =>
      guard(() async => (await _remote.getPromotions()).map((dto) => dto.toDomain()).toList());
}

class LocalProductsRepositoryImpl implements LocalProductsRepository {
  const LocalProductsRepositoryImpl(this._remote);

  final LocalProductsRemoteDataSource _remote;

  @override
  Future<Result<List<ProductHit>>> localProducts() =>
      guard(() async => (await _remote.localProducts()).map((dto) => dto.toDomain()).toList());
}
