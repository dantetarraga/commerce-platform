import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/infrastructure/search_infrastructure.dart';
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

@riverpod
Future<SearchResults> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final location = ref.watch(currentDeliveryLocationProvider).coordinates;
  return SearchCatalog(ref.watch(searchRepositoryProvider)).call(query, location).then((r) => r.getOrThrow());
}
