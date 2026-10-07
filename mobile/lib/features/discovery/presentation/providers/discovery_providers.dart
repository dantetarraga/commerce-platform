import 'dart:async';

import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/discovery/domain/moment.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/infrastructure/datasources/local_products_remote_data_source.dart';
import 'package:chaski/features/discovery/infrastructure/repositories/discovery_repositories.dart';
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
