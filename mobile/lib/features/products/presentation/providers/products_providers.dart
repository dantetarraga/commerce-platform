import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:chaski/features/products/domain/entities/product_selection.dart';
import 'package:chaski/features/products/domain/repositories/products_repository.dart';
import 'package:chaski/features/products/domain/usecases/get_product_detail.dart';
import 'package:chaski/features/products/infrastructure/datasources/remote/products_remote_data_source.dart';
import 'package:chaski/features/products/infrastructure/repositories/products_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'products_providers.g.dart';

@Riverpod(keepAlive: true)
ProductsRemoteDataSource productsRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeProductsRemoteDataSource(ref.watch(fakeBackendProvider))
    : ApiProductsRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
ProductsRepository productsRepository(Ref ref) => ProductsRepositoryImpl(ref.watch(productsRemoteDataSourceProvider));

@riverpod
Future<Product> productDetail(Ref ref, String productId) =>
    GetProductDetail(ref.watch(productsRepositoryProvider)).call(productId).then((r) => r.getOrThrow());

/// Selección en curso del detalle de producto. La lógica vive en la entidad;
/// el controller solo expone sus transiciones a la UI.
@riverpod
class ProductSelectionController extends _$ProductSelectionController {
  @override
  ProductSelection build(Product product) => ProductSelection.initial(product);

  void selectVariant(String variantId) => state = state.selectVariant(variantId);

  void toggleValue(String optionId, String valueId) => state = state.toggleValue(optionId, valueId);

  void setQuantity(Quantity quantity) => state = state.withQuantity(quantity);

  void setNotes(String notes) => state = state.withNotes(notes);
}
