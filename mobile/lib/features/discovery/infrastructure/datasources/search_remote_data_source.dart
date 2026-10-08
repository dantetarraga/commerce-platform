import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_catalog_json.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/utils/text_utils.dart';
import 'package:chaski/features/discovery/infrastructure/models/search_dtos.dart';

abstract interface class SearchRemoteDataSource {
  Future<SearchResponseDto> search(String query, GeoCoordinates location, {bool openOnly = false});
}

class ApiSearchRemoteDataSource implements SearchRemoteDataSource {
  const ApiSearchRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<SearchResponseDto> search(String query, GeoCoordinates location, {bool openOnly = false}) async {
    final data = await _api.get(
      '/search',
      query: {'q': query, 'lat': location.latitude, 'lng': location.longitude, if (openOnly) 'openOnly': true},
    );
    return SearchResponseDto.fromJson(data as Map<String, dynamic>);
  }
}

/// Búsqueda sin tildes sobre el catálogo de prueba (imita unaccent + pg_trgm).
class FakeSearchRemoteDataSource implements SearchRemoteDataSource {
  const FakeSearchRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<SearchResponseDto> search(String query, GeoCoordinates location, {bool openOnly = false}) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final needle = normalizeForSearch(query);
    bool matches(Object? text) => text is String && normalizeForSearch(text).contains(needle);

    final stores = _backend.listOf(catalog, 'stores');
    final products = _backend.listOf(catalog, 'products');
    return SearchResponseDto.fromJson({
      'stores': [
        for (final s in stores)
          if ((matches(s['name']) || matches(s['description'])) && (!openOnly || s['isOpenNow'] == true))
            _backend.storeSummaryJson(s),
      ],
      'products': [
        for (final p in products)
          if (p['isAvailable'] == true && (matches(p['name']) || matches(p['description'])))
            {
              ..._backend.menuItemJson(p),
              'storeId': p['storeId'],
              'storeName': _backend.findById(stores, p['storeId'] as String)?['name'],
            },
      ],
    });
  }
}
