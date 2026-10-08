import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/stores/domain/entities/category.dart';
import 'package:apamuy/features/stores/domain/entities/store_detail.dart';
import 'package:apamuy/features/stores/domain/entities/store_menu.dart';
import 'package:apamuy/features/stores/domain/entities/store_page.dart';
import 'package:apamuy/features/stores/domain/entities/store_query.dart';
import 'package:apamuy/features/stores/domain/repositories/stores_repository.dart';
import 'package:apamuy/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:apamuy/features/stores/infrastructure/mappers/store_mapper.dart';

/// Traduce DTOs a entidades y excepciones a `Failure`.
class StoresRepositoryImpl implements StoresRepository {
  StoresRepositoryImpl(this._remote);

  final StoresRemoteDataSource _remote;
  // Sin caché: los abiertos por categoría cambian con la hora y la ubicación.
  @override
  Future<Result<List<Category>>> getCategories(GeoCoordinates location) =>
      guard(() async => (await _remote.getCategories(location)).map((c) => c.toDomain()).toList());

  @override
  Future<Result<StorePage>> getStores(StoreQuery query) =>
      guard(() async => (await _remote.getStores(query)).toDomain());

  @override
  Future<Result<StoreDetail>> getStoreDetail(String storeId, {GeoCoordinates? near}) =>
      guard(() async => (await _remote.getStoreDetail(storeId, near: near)).toDomain());

  @override
  Future<Result<List<MenuItem>>> searchMenu(String storeId, String query) =>
      guard(() async => (await _remote.searchMenu(storeId, query)).map((dto) => dto.toDomain()).toList());

  @override
  Future<Result<StoreMenu>> getStoreMenu(String storeId) =>
      guard(() async => (await _remote.getStoreMenu(storeId)).toDomain());
}
