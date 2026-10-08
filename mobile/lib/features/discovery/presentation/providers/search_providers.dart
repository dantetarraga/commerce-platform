import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/maps/delivery_location.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/features/discovery/domain/search.dart';
import 'package:apamuy/features/discovery/infrastructure/datasources/search_remote_data_source.dart';
import 'package:apamuy/features/discovery/infrastructure/repositories/discovery_repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_providers.g.dart';

@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) => SearchRepositoryImpl(
  ref.watch(appEnvProvider).useFakeData
      ? FakeSearchRemoteDataSource(ref.watch(fakeBackendProvider))
      : ApiSearchRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Texto de búsqueda ya "debounceado" por la UI.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Chip "Abierto ahora" de los resultados: se manda al backend.
@riverpod
class SearchOpenOnly extends _$SearchOpenOnly {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@riverpod
Future<SearchResults> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final openOnly = ref.watch(searchOpenOnlyProvider);
  final location = ref.watch(currentDeliveryLocationProvider).coordinates;
  return SearchCatalog(
    ref.watch(searchRepositoryProvider),
  ).call(query, location, openOnly: openOnly).then((r) => r.getOrThrow());
}
