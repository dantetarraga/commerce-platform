import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_catalog_json.dart';
import 'package:chaski/core/utils/text_utils.dart';
import 'package:chaski/features/stores/domain/entities/store_filter.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/models/store_dtos.dart';

/// Simula `GET /categories`, `/stores`, `/stores/:id` y `/stores/:id/products`
/// a partir de `assets/fixtures/catalog.json`.
class FakeStoresRemoteDataSource implements StoresRemoteDataSource {
  const FakeStoresRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<CategoryDto>> getCategories(GeoCoordinates location) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final open = _backend.listOf(catalog, 'stores').where((s) => s['deliversToYou'] == true && s['isOpenNow'] == true);
    return [
      for (final c in _backend.listOf(catalog, 'categories'))
        CategoryDto.fromJson({...c, 'openStoreCount': open.where((s) => (s['categoryIds'] as List).contains(c['id'])).length}),
    ];
  }

  /// Como `?filters=` del backend, sobre el JSON del catálogo de prueba.
  static bool _accepts(Map<String, dynamic> s, StoreFilter filter) => switch (filter) {
    StoreFilter.openNow => s['isOpenNow'] == true,
    StoreFilter.freeDelivery => s['deliveryFee'] == 0,
    StoreFilter.topRated => (s['ratingCount'] as num) > 0 && (s['ratingAvg'] as num) >= 4.5,
    StoreFilter.noMinimum => s['minOrderAmount'] == 0,
    StoreFilter.offers => s['promoLabel'] != null,
  };

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

    final openCount = stores.where((s) => s['isOpenNow'] == true).length;
    final filtered = stores.where((s) => query.filters.every((f) => _accepts(s, f))).toList();
    final rows = query.openFirst
        ? [...filtered.where((s) => s['isOpenNow'] == true), ...filtered.where((s) => s['isOpenNow'] != true)]
        : filtered;
    final start = (query.page - 1) * query.limit;
    final pageItems = rows.skip(start).take(query.limit);
    return StorePageDto.fromJson({
      'items': pageItems.map(_backend.storeSummaryJson).toList(),
      'page': query.page,
      'limit': query.limit,
      'total': rows.length,
      'openCount': openCount,
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

  /// Como el backend: nombre o descripción sin tildes, en el orden de la carta y sin repetir.
  @override
  Future<List<MenuItemDto>> searchMenu(String storeId, String query) async {
    final menu = await getStoreMenu(storeId);
    final needle = normalizeForSearch(query);
    final seen = <String>{};
    return [
      for (final section in menu.sections)
        for (final item in section.products)
          if ((needle.isEmpty || foldAccents('${item.name} ${item.description ?? ''}').contains(needle)) && seen.add(item.id))
            item,
    ];
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
