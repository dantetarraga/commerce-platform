import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_catalog_json.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/models/store_dtos.dart';

/// Simula `GET /categories`, `/stores`, `/stores/:id` y `/stores/:id/products`
/// a partir de `assets/fixtures/catalog.json`.
class FakeStoresRemoteDataSource implements StoresRemoteDataSource {
  const FakeStoresRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<CategoryDto>> getCategories() async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    return _backend.listOf(catalog, 'categories').map(CategoryDto.fromJson).toList();
  }

  @override
  Future<StorePageDto> getStores(StoreQuery query) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final stores = _backend
        .listOf(catalog, 'stores')
        .where((s) => s['deliversToYou'] == true)
        .where((s) => query.categoryId == null || (s['categoryIds'] as List).contains(query.categoryId))
        .toList();

    int byNum(String key, Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a[key] as num).compareTo(b[key] as num);
    switch (query.sort) {
      case StoreSort.distance:
        stores.sort((a, b) => byNum('distanceKm', a, b));
      case StoreSort.popular:
        stores.sort((a, b) => byNum('popularity', b, a));
      case StoreSort.rating:
        stores.sort((a, b) => byNum('ratingAvg', b, a));
    }

    final start = (query.page - 1) * query.limit;
    final pageItems = stores.skip(start).take(query.limit);
    return StorePageDto.fromJson({
      'items': pageItems.map(_backend.storeSummaryJson).toList(),
      'page': query.page,
      'limit': query.limit,
      'total': stores.length,
    });
  }

  @override
  Future<StoreDetailDto> getStoreDetail(String storeId, {GeoCoordinates? near}) async {
    await _backend.delay();
    final store = await _findStore(storeId);
    return StoreDetailDto.fromJson({
      ..._backend.storeSummaryJson(store),
      'description': store['description'],
      'addressLine': store['addressLine'],
      'phone': store['phone'],
      'schedules': store['schedules'],
      'ownerName': store['ownerName'],
      'attendingSince': store['attendingSince'],
    });
  }

  @override
  Future<StoreMenuDto> getStoreMenu(String storeId) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final store = await _findStore(storeId);
    final products = _backend.listOf(catalog, 'products');
    final sections = (store['menuSections'] as List<dynamic>).cast<Map<String, dynamic>>();
    return StoreMenuDto.fromJson({
      'sections': [
        for (final section in sections)
          {
            'id': section['id'],
            'name': section['name'],
            'products': [
              for (final id in (section['productIds'] as List).cast<String>())
                if (_backend.findById(products, id) case final product?) _backend.menuItemJson(product),
            ],
          },
      ],
    });
  }

  Future<Map<String, dynamic>> _findStore(String storeId) async {
    final catalog = await _backend.catalog();
    final store = _backend.findById(_backend.listOf(catalog, 'stores'), storeId);
    if (store == null) {
      throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Este negocio ya no está disponible.');
    }
    return store;
  }
}
