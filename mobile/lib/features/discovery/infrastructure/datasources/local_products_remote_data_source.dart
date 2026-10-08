import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/fake/fake_catalog_json.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/discovery/infrastructure/models/search_dtos.dart';

/// `GET /discovery/local-products`: productos hechos en la ciudad.
abstract interface class LocalProductsRemoteDataSource {
  Future<List<ProductHitDto>> localProducts();
}

class ApiLocalProductsRemoteDataSource implements LocalProductsRemoteDataSource {
  const ApiLocalProductsRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<ProductHitDto>> localProducts() async {
    final data = await _api.get('/discovery/local-products');
    return ((data as Map<String, dynamic>)['items'] as List).cast<Map<String, dynamic>>().map(ProductHitDto.fromJson).toList();
  }
}

class FakeLocalProductsRemoteDataSource implements LocalProductsRemoteDataSource {
  const FakeLocalProductsRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<ProductHitDto>> localProducts() async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final stores = _backend.listOf(catalog, 'stores');
    return [
      for (final p in _backend.listOf(catalog, 'products'))
        if (p['isLocal'] == true && p['isAvailable'] == true)
          ProductHitDto.fromJson({
            ..._backend.menuItemJson(p),
            'storeId': p['storeId'],
            'storeName': _backend.findById(stores, p['storeId'] as String)?['name'],
          }),
    ];
  }
}
