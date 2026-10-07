import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/infrastructure/popular_searches_infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers escritos a mano (sin codegen).

final popularSearchesRepositoryProvider = Provider<PopularSearchesRepository>(
  (ref) => ref.watch(appEnvProvider).useFakeData
      ? FakePopularSearchesRepository(ref.watch(fakeBackendProvider))
      : ApiPopularSearchesRepository(ref.watch(apiClientProvider)),
);

/// "Lo más pedido en Espinar" (estado inicial de Explorar y sugerencias).
final popularSearchesProvider = FutureProvider<List<PopularSearch>>(
  (ref) async => (await ref.watch(popularSearchesRepositoryProvider).popular()).getOrThrow(),
);
