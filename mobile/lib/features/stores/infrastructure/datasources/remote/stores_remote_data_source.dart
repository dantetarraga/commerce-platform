import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/network/location_query.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/infrastructure/models/store_dtos.dart';

abstract interface class StoresRemoteDataSource {
  Future<List<CategoryDto>> getCategories(GeoCoordinates location);

  Future<StorePageDto> getStores(StoreQuery query);

  Future<StoreDetailDto> getStoreDetail(String storeId, {GeoCoordinates? near});

  Future<StoreMenuDto> getStoreMenu(String storeId);

  /// `GET /stores/:id/products/search?q=`: lo que coincide, en el orden de la carta.
  Future<List<MenuItemDto>> searchMenu(String storeId, String query);
}

class ApiStoresRemoteDataSource implements StoresRemoteDataSource {
  const ApiStoresRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<CategoryDto>> getCategories(GeoCoordinates location) async {
    final data = await _api.get('/categories', query: locationQuery(location)) as List<dynamic>;
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
        if (query.filters.isNotEmpty) 'filters': query.filters.map((f) => f.apiName).join(','),
        if (query.openFirst) 'openFirst': true,
        'page': query.page,
        'limit': query.limit,
      },
    );
    return StorePageDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<StoreDetailDto> getStoreDetail(String storeId, {GeoCoordinates? near}) async {
    final data = await _api.get('/stores/$storeId', query: locationQuery(near));
    return StoreDetailDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<MenuItemDto>> searchMenu(String storeId, String query) async {
    final data = await _api.get('/stores/$storeId/products/search', query: {if (query.trim().isNotEmpty) 'q': query.trim()});
    return [
      for (final item in ((data as Map<String, dynamic>)['items'] as List).cast<Map<String, dynamic>>()) MenuItemDto.fromJson(item),
    ];
  }

  @override
  Future<StoreMenuDto> getStoreMenu(String storeId) async {
    final data = await _api.get('/stores/$storeId/products');
    return StoreMenuDto.fromJson(data as Map<String, dynamic>);
  }
}
