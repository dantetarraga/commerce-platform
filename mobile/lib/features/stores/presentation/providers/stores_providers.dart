import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_filter.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_page.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';
import 'package:chaski/features/stores/domain/usecases/store_usecases.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/fake_stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/repositories/stores_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stores_providers.g.dart';

@Riverpod(keepAlive: true)
StoresRemoteDataSource storesRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeStoresRemoteDataSource(ref.watch(fakeBackendProvider))
    : ApiStoresRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
StoresRepository storesRepository(Ref ref) => StoresRepositoryImpl(ref.watch(storesRemoteDataSourceProvider));

/// Categorías con sus negocios abiertos en la ubicación de entrega actual.
@riverpod
Future<List<Category>> categories(Ref ref) {
  final location = ref.watch(currentDeliveryLocationProvider).coordinates;
  return GetCategories(ref.watch(storesRepositoryProvider)).call(location).then((r) => r.getOrThrow());
}

/// Negocios para la ubicación de entrega actual.
@riverpod
Future<StorePage> stores(
  Ref ref, {
  StoreSort sort = StoreSort.distance,
  String? categoryId,
  StoreFilters filters = StoreFilters.none,
  int limit = 20,
}) {
  final location = ref.watch(currentDeliveryLocationProvider);
  final query = StoreQuery(
    location: location.coordinates,
    sort: sort,
    categoryId: categoryId,
    filters: filters.values,
    limit: limit,
  );
  return GetStores(ref.watch(storesRepositoryProvider)).call(query).then((r) => r.getOrThrow());
}

/// Distancia, delivery y ETA dependen de la ubicación de entrega actual.
@riverpod
Future<StoreDetail> storeDetail(Ref ref, String storeId) {
  final near = ref.watch(currentDeliveryLocationProvider).coordinates;
  return GetStoreDetail(ref.watch(storesRepositoryProvider)).call(storeId, near: near).then((r) => r.getOrThrow());
}

@riverpod
Future<StoreMenu> storeMenu(Ref ref, String storeId) =>
    GetStoreMenu(ref.watch(storesRepositoryProvider)).call(storeId).then((r) => r.getOrThrow());

/// Lo que coincide con [query] en la carta del negocio (busca el backend).
@riverpod
Future<List<MenuItem>> menuSearch(Ref ref, String storeId, String query) =>
    ref.watch(storesRepositoryProvider).searchMenu(storeId, query).then((r) => r.getOrThrow());
