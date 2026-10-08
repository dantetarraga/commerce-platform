import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/domain/repositories/products_repository.dart';

class GetProductDetail {
  const GetProductDetail(this._repository);

  final ProductsRepository _repository;

  Future<Result<Product>> call(String productId, {GeoCoordinates? near}) =>
      _repository.getProduct(productId, near: near);
}
