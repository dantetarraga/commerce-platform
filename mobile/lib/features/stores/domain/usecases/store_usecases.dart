import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_page.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';

class GetCategories {
  const GetCategories(this._repository);
  final StoresRepository _repository;

  Future<Result<List<Category>>> call(GeoCoordinates location) => _repository.getCategories(location);
}

class GetStores {
  const GetStores(this._repository);
  final StoresRepository _repository;

  Future<Result<StorePage>> call(StoreQuery query) => _repository.getStores(query);
}

class GetStoreDetail {
  const GetStoreDetail(this._repository);
  final StoresRepository _repository;

  Future<Result<StoreDetail>> call(String storeId, {GeoCoordinates? near}) =>
      _repository.getStoreDetail(storeId, near: near);
}

class GetStoreMenu {
  const GetStoreMenu(this._repository);
  final StoresRepository _repository;

  Future<Result<StoreMenu>> call(String storeId) => _repository.getStoreMenu(storeId);
}
