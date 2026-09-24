import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/domain/page_result.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';
import 'package:chaski/features/stores/domain/usecases/store_usecases.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/fake_stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/repositories/stores_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stores_providers.g.dart';

// ── Inyección de dependencias ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
StoresRemoteDataSource storesRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeStoresRemoteDataSource(ref.watch(fakeBackendProvider))
    : ApiStoresRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
StoresRepository storesRepository(Ref ref) => StoresRepositoryImpl(ref.watch(storesRemoteDataSourceProvider));

// ── Consultas (API pública del feature) ──────────────────────────────────────

@riverpod
Future<List<Category>> categories(Ref ref) =>
    GetCategories(ref.watch(storesRepositoryProvider)).call().then((r) => r.getOrThrow());

/// Negocios para la ubicación de entrega actual.
@riverpod
Future<PageResult<StoreSummary>> stores(Ref ref, {StoreSort sort = StoreSort.distance, String? categoryId}) {
  final location = ref.watch(currentDeliveryLocationProvider);
  final query = StoreQuery(location: location.coordinates, sort: sort, categoryId: categoryId);
  return GetStores(ref.watch(storesRepositoryProvider)).call(query).then((r) => r.getOrThrow());
}

@riverpod
Future<StoreDetail> storeDetail(Ref ref, String storeId) =>
    GetStoreDetail(ref.watch(storesRepositoryProvider)).call(storeId).then((r) => r.getOrThrow());

@riverpod
Future<StoreMenu> storeMenu(Ref ref, String storeId) =>
    GetStoreMenu(ref.watch(storesRepositoryProvider)).call(storeId).then((r) => r.getOrThrow());
