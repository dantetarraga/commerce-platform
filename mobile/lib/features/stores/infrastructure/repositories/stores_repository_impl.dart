import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/page_result.dart';
import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/mappers/store_mapper.dart';

/// Traduce DTOs a entidades y excepciones a `Failure`. Las categorías cambian
/// muy poco, así que se guardan en memoria durante la sesión.
class StoresRepositoryImpl implements StoresRepository {
  StoresRepositoryImpl(this._remote);

  final StoresRemoteDataSource _remote;
  List<Category>? _categoriesCache;

  @override
  Future<Result<List<Category>>> getCategories() async {
    if (_categoriesCache case final cached?) return Result.ok(cached);
    final result = await guard(() async => (await _remote.getCategories()).map((c) => c.toDomain()).toList());
    if (result case Ok(:final value)) _categoriesCache = value;
    return result;
  }

  @override
  Future<Result<PageResult<StoreSummary>>> getStores(StoreQuery query) =>
      guard(() async => (await _remote.getStores(query)).toDomain());

  @override
  Future<Result<StoreDetail>> getStoreDetail(String storeId, {GeoCoordinates? near}) =>
      guard(() async => (await _remote.getStoreDetail(storeId, near: near)).toDomain());

  @override
  Future<Result<StoreMenu>> getStoreMenu(String storeId) =>
      guard(() async => (await _remote.getStoreMenu(storeId)).toDomain());
}
