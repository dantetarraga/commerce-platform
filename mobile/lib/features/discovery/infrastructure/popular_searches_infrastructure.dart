import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/utils/text_utils.dart';
import 'package:chaski/features/discovery/domain/search.dart';

/// `GET /discovery/popular-searches`: `[{term, storeCount}]`.
class ApiPopularSearchesRepository implements PopularSearchesRepository {
  const ApiPopularSearchesRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<PopularSearch>>> popular() => guard(() async {
    final data = await _api.get('/discovery/popular-searches') as List<dynamic>;
    return [
      for (final e in data.cast<Map<String, dynamic>>())
        PopularSearch(term: e['term'] as String, storeCount: (e['storeCount'] as num).toInt()),
    ];
  });
}

/// Lo más pedido de la ciudad: términos fijos, con el conteo real de negocios
/// del catálogo de prueba que los venden.
class FakePopularSearchesRepository implements PopularSearchesRepository {
  const FakePopularSearchesRepository(this._backend);

  static const _terms = ['Caldo', 'Pollo a la brasa', 'Queso fresco', 'Pan chuta', 'Pizza', 'Menú del día', 'Paracetamol'];

  final FakeBackend _backend;

  @override
  Future<Result<List<PopularSearch>>> popular() => guard(() async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final products = _backend.listOf(catalog, 'products');
    return [
      for (final term in _terms)
        if (_storesSelling(products, term) case final count when count > 0) PopularSearch(term: term, storeCount: count),
    ];
  });

  int _storesSelling(List<Map<String, dynamic>> products, String term) {
    final needle = normalizeForSearch(term);
    return {
      for (final p in products)
        if (p['isAvailable'] == true && p['name'] is String && normalizeForSearch(p['name'] as String).contains(needle)) p['storeId'],
    }.length;
  }
}
