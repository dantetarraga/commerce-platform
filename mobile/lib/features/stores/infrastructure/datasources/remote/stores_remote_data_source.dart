import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/infrastructure/models/store_dtos.dart';

abstract interface class StoresRemoteDataSource {
  Future<List<CategoryDto>> getCategories();

  Future<StorePageDto> getStores(StoreQuery query);

  Future<StoreDetailDto> getStoreDetail(String storeId);

  Future<StoreMenuDto> getStoreMenu(String storeId);
}

class ApiStoresRemoteDataSource implements StoresRemoteDataSource {
  const ApiStoresRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<CategoryDto>> getCategories() async {
    final data = await _api.get('/categories') as List<dynamic>;
    return data.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<StorePageDto> getStores(StoreQuery query) async {
    final data = await _api.get(
      '/stores',
      query: {
        'lat': query.location.latitude,
        'lng': query.location.longitude,
        'sort': query.sort.name,
        'categoryId': ?query.categoryId,
        'page': query.page,
        'limit': query.limit,
      },
    );
    return StorePageDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<StoreDetailDto> getStoreDetail(String storeId) async {
    final data = await _api.get('/stores/$storeId');
    return StoreDetailDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<StoreMenuDto> getStoreMenu(String storeId) async {
    final data = await _api.get('/stores/$storeId/products');
    return StoreMenuDto.fromJson(data as Map<String, dynamic>);
  }
}
