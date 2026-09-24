import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:chaski/features/products/domain/repositories/products_repository.dart';

class GetProductDetail {
  const GetProductDetail(this._repository);

  final ProductsRepository _repository;

  Future<Result<Product>> call(String productId) => _repository.getProduct(productId);
}
