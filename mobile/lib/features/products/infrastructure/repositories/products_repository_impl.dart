import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/domain/repositories/products_repository.dart';
import 'package:apamuy/features/products/infrastructure/datasources/remote/products_remote_data_source.dart';
import 'package:apamuy/features/products/infrastructure/mappers/product_mapper.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Result<Product>> getProduct(String productId, {GeoCoordinates? near}) =>
      guard(() async => (await _remote.getProduct(productId, near: near)).toDomain());
}
