import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_catalog_json.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/products/infrastructure/models/product_dtos.dart';

abstract interface class ProductsRemoteDataSource {
  Future<ProductDetailDto> getProduct(String productId);
}

class ApiProductsRemoteDataSource implements ProductsRemoteDataSource {
  const ApiProductsRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<ProductDetailDto> getProduct(String productId) async {
    final data = await _api.get('/products/$productId');
    return ProductDetailDto.fromJson(data as Map<String, dynamic>);
  }
}

/// Simula `GET /products/:id` con el catálogo de prueba.
class FakeProductsRemoteDataSource implements ProductsRemoteDataSource {
  const FakeProductsRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<ProductDetailDto> getProduct(String productId) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final product = _backend.findById(_backend.listOf(catalog, 'products'), productId);
    if (product == null) {
      throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Este producto ya no está disponible.');
    }
    final store = _backend.findById(_backend.listOf(catalog, 'stores'), product['storeId'] as String)!;

    Map<String, Object?> withMoney(Map<String, dynamic> json, String key) =>
        {...json, key: _backend.money(json[key] as int)};

    return ProductDetailDto.fromJson({
      ...product,
      'storeName': store['name'],
      'store': {
        'logoUrl': store['logoUrl'],
        'deliveryFee': _backend.money(store['deliveryFee'] as int),
        'minOrderAmount': _backend.money(store['minOrderAmount'] as int),
        'etaMinutes': store['etaMinutes'],
        'isOpenNow': store['isOpenNow'],
      },
      'basePrice': _backend.money(product['basePrice'] as int),
      'variants': [
        for (final v in (product['variants'] as List).cast<Map<String, dynamic>>()) withMoney(v, 'price'),
      ],
      'options': [
        for (final o in (product['options'] as List).cast<Map<String, dynamic>>())
          {
            ...o,
            'values': [
              for (final value in (o['values'] as List).cast<Map<String, dynamic>>()) withMoney(value, 'priceDelta'),
            ],
          },
      ],
    });
  }
}
