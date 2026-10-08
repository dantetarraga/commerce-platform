import 'dart:async';

import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/features/discovery/domain/moment.dart';
import 'package:apamuy/features/discovery/domain/search.dart';
import 'package:apamuy/features/discovery/infrastructure/datasources/local_products_remote_data_source.dart';
import 'package:apamuy/features/discovery/infrastructure/repositories/discovery_repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_providers.g.dart';

@Riverpod(keepAlive: true)
LocalProductsRepository localProductsRepository(Ref ref) => LocalProductsRepositoryImpl(
  ref.watch(appEnvProvider).useFakeData
      ? FakeLocalProductsRemoteDataSource(ref.watch(fakeBackendProvider))
      : ApiLocalProductsRemoteDataSource(ref.watch(apiClientProvider)),
);

/// "Hecho en Espinar": productos de la ciudad.
@riverpod
Future<List<ProductHit>> localProducts(Ref ref) =>
    ref.watch(localProductsRepositoryProvider).localProducts().then((r) => r.getOrThrow());

/// Momento actual; se recalcula cada 10 minutos.
@Riverpod(keepAlive: true)
class CurrentMoment extends _$CurrentMoment {
  @override
  Moment build() {
    final timer = Timer.periodic(const Duration(minutes: 10), (_) => state = Moment.at(DateTime.now()));
    ref.onDispose(timer.cancel);
    return Moment.at(DateTime.now());
  }
}
