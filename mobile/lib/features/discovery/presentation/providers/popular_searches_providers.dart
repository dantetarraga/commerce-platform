import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/infrastructure/repositories/popular_searches_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'popular_searches_providers.g.dart';

@Riverpod(keepAlive: true)
PopularSearchesRepository popularSearchesRepository(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakePopularSearchesRepository(ref.watch(fakeBackendProvider))
    : ApiPopularSearchesRepository(ref.watch(apiClientProvider));

/// "Lo más pedido en Espinar" (estado inicial de Explorar y sugerencias).
@Riverpod(keepAlive: true)
Future<List<PopularSearch>> popularSearches(Ref ref) =>
    ref.watch(popularSearchesRepositoryProvider).popular().then((r) => r.getOrThrow());
