import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:chaski/features/products/domain/repositories/products_repository.dart';
import 'package:chaski/features/products/infrastructure/datasources/remote/products_remote_data_source.dart';
import 'package:chaski/features/products/infrastructure/mappers/product_mapper.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Result<Product>> getProduct(String productId) =>
      guard(() async => (await _remote.getProduct(productId)).toDomain());
}
