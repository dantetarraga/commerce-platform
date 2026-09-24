import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/products/domain/entities/product.dart';

abstract interface class ProductsRepository {
  Future<Result<Product>> getProduct(String productId);
}
