import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/page_result.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';

abstract interface class StoresRepository {
  Future<Result<List<Category>>> getCategories();

  Future<Result<PageResult<StoreSummary>>> getStores(StoreQuery query);

  /// [near] = ubicación de entrega, para distancia, delivery y ETA.
  Future<Result<StoreDetail>> getStoreDetail(String storeId, {GeoCoordinates? near});

  Future<Result<StoreMenu>> getStoreMenu(String storeId);
}
