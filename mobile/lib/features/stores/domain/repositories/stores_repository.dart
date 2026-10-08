import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_page.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';

abstract interface class StoresRepository {
  /// Con cuántos negocios abiertos llegan a [location] en cada una.
  Future<Result<List<Category>>> getCategories(GeoCoordinates location);

  Future<Result<StorePage>> getStores(StoreQuery query);

  /// [near] = ubicación de entrega, para distancia, delivery y ETA.
  Future<Result<StoreDetail>> getStoreDetail(String storeId, {GeoCoordinates? near});

  Future<Result<StoreMenu>> getStoreMenu(String storeId);

  /// Busca en la carta (lo resuelve el backend). Vacío: toda la carta.
  Future<Result<List<MenuItem>>> searchMenu(String storeId, String query);
}
