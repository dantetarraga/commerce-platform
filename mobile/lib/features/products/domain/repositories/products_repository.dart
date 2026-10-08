import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';

abstract interface class ProductsRepository {
  /// [near] = ubicación de entrega, para calcular el delivery del negocio.
  Future<Result<Product>> getProduct(String productId, {GeoCoordinates? near});
}
